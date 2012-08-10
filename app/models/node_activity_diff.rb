# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class NodeActivityDiff < ActiveRecord::Base
  belongs_to :group
  extend YearWeek
  

  scope :by_year_week, lambda {|year,week| where(:year => year).where(:week => week) }
  scope :overall, where(:group_id => 0)
  scope :by_metric, lambda{|metric| where(:metric => metric)}
  scope :by_node_scope, lambda{|node_scope| where(:node_scope => node_scope)}
  scope :by_activity_scope, lambda{|activity_scope| where(:activity_scope => activity_scope)}
  scope :latest_week, lambda{(year,week) = Analytic.latest_year_week; by_year_week(year,week)}
  scope :by_n_a_m, lambda{|n,a,m| by_node_scope(n).by_activity_scope(a).by_metric(m)}

  def self.rebuild
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    NodeActivity::NODE_SCOPES.each do |node_scope|
      NodeActivity::ACTIVITY_SCOPES.each do |activity_scope|
        self.rebuild_by_group(:node_scope => node_scope, :activity_scope => activity_scope)
        Group.launched.each do |group|
          self.rebuild_by_group(:group => group, :node_scope => node_scope, :activity_scope => activity_scope)
        end
      end
    end
    true
  end
  
  
  def self.rebuild_by_group(options = {})
    group = options[:group]
    activity_scope = options[:activity_scope]
    node_scope = options[:node_scope]

    if(group.nil?)
      group_id = 0
      week_stats = NodeActivity.send(node_scope).stats_by_yearweek(activity_scope)
    else
      group_id = group.id
      week_stats = group.node_activities.send(node_scope).stats_by_yearweek(activity_scope)
    end
    
    insert_values = []
    earliest_created_at = ((group.nil?) ? Node.minimum(:created_at) : group.nodes.minimum(:created_at))
    if(!earliest_created_at.nil?)
      start_date = earliest_created_at.to_date
      (eyear,eweek) = Analytic.latest_year_week
      (sow,end_date) = self.date_pair_for_year_week(eyear,eweek)
      yearweeks = self.year_weeks_between_dates(start_date,end_date)
      running_change = []
      running_difference = []
    
      yearweeks.each do |year,week|     
        current_key_string = self.yearweek(year,week)
        previous_year_key_string = self.yearweek(year-1,week)
        (previous_year,previous_week) = Analytic.previous_year_week(year,week)
        previous_week_key_string = self.yearweek(previous_year,previous_week)
        
        # metrics
        [:contributions,:items,:contributors].each do |metric|

          metric_value = (week_stats[current_key_string] ? week_stats[current_key_string][metric] : 0)
          previous_week = (week_stats[previous_week_key_string]  ? week_stats[previous_week_key_string][metric] : 0)        
          previous_year = (week_stats[previous_year_key_string]  ? week_stats[previous_year_key_string][metric] : 0)        

          # pct_difference
          if((metric_value + previous_week) == 0)
             pct_difference_week = 0
          else
             pct_difference_week = (metric_value - previous_week) / ((metric_value + previous_week) / 2)
          end   
          if((metric_value + previous_year) == 0)
             pct_difference_year = 0
          else
             pct_difference_year = (metric_value - previous_year) / ((metric_value + previous_year) / 2)
          end
          # pct_change
          if(previous_week == 0)
            pct_change_week = 'NULL'
          else
            pct_change_week = (metric_value - previous_week) / previous_week
          end
          if(previous_year == 0)
            pct_change_year = 'NULL'
          else
            pct_change_year = (metric_value - previous_year) / previous_year
          end
        
          if(pct_change_week != 'NULL')
            running_change.push(pct_change_week)
            if(running_change.size > Settings.recent_weeks)
              running_change.shift
              recent_pct_change = running_change.sum
            elsif(running_change.size == Settings.recent_weeks)
              recent_pct_change = running_change.sum
            else
              recent_pct_change = 'NULL'
            end
          else
            recent_pct_change = 'NULL'
          end
        
          if(pct_difference_week != 'NULL')  
            running_difference.push(pct_difference_week)
            if(running_difference.size > Settings.recent_weeks)
              running_difference.shift
              recent_pct_difference = running_difference.sum
            elsif(running_difference.size == Settings.recent_weeks)
              recent_pct_difference = running_difference.sum
            else
              recent_pct_difference = 'NULL'
            end
          else
            recent_pct_difference = 'NULL'
          end
        
              
          insert_list = []
          insert_list << group_id
          insert_list << ActiveRecord::Base.quote_value(node_scope)
          insert_list << ActiveRecord::Base.quote_value(activity_scope)
          insert_list << ActiveRecord::Base.quote_value(metric.to_s)
          insert_list << self.yearweek(year,week)
          insert_list << year
          insert_list << week
          insert_list << ActiveRecord::Base.quote_value(self.year_week_date(year,week))
          insert_list << metric_value
          insert_list << previous_week
          insert_list << previous_year
          insert_list << pct_difference_week
          insert_list << pct_difference_year
          insert_list << recent_pct_difference
          insert_list << pct_change_week
          insert_list << pct_change_year
          insert_list << recent_pct_change
          insert_list << 'NOW()'        
          insert_values << "(#{insert_list.join(',')})"
        end # metric
      end # year-week
    end # created_at nil? check
    if(!insert_values.blank?)
      columns = self.column_names.reject{|n| n == "id"}
      insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end      
  end

  def self.stats_to_graph_data(showrolling = true)
    returndata = []
    value_data = []
    rolling_data = []
    with_scope do
      running_total = 0 
      weekcount = 0
      self.order('yearweek').each do |nad|
        weekcount += 1
        running_total += nad.metric_value
        rolling_data << [nad.yearweek_date,(running_total / weekcount)]
        value_data << [nad.yearweek_date,nad.metric_value]
      end
    end
    if(showrolling)
      returndata = [value_data,rolling_data]
    else
      returndata = [value_data]
    end
    returndata
  end
end
