# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class LandingDiff < ActiveRecord::Base
  belongs_to :group
  extend YearWeek
  
  scope :by_year_week, lambda {|year,week| where(:year => year).where(:week => week) }
  scope :overall, where(:group_id => 0)
  scope :by_metric, lambda{|metric| where(:metric => metric)}
  scope :latest_week, lambda{(year,week) = Analytic.latest_year_week; by_year_week(year,week)}

  
  
  def self.max_for_metric(metric,nearest = nil)
    with_scope do
      max = where(:metric => metric).maximum(:stat)
      if(nearest)
        max = max + nearest - (max % nearest)
      end
    end
  end
  
  def self.rebuild
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    self.rebuild_by_group_and_metric(:metric => 'views')
    Group.launched.each do |group|
      # views only for now
      self.rebuild_by_group_and_metric(:group => group, :metric => 'views')
    end
  end
  
  
  def self.rebuild_by_group_and_metric(options = {})
    
    group = options[:group]
    if(group.nil?)
      group_id = 0
      week_stats = LandingStat.overall.sum_metric_by_yearweek(options[:metric])
    else
      group_id = group.id
      week_stats = group.landing_stats.sum_metric_by_yearweek(options[:metric])
    end
    
    insert_values = []
    earliest_created_at = ((group.nil?) ? Page.minimum(:created_at) : group.pages.minimum(:created_at))
    if(!earliest_created_at.nil?)
      start_date = earliest_created_at.to_date
      yearweeks = Analytic.year_weeks_from_date(start_date)
      running_change = []
      running_difference = []
    
      yearweeks.each do |year,week|     
        current_key_string = self.yearweek(year,week)
        previous_year_key_string = self.yearweek(year-1,week)
        (previous_year,previous_week) = Analytic.previous_year_week(year,week)
        previous_week_key_string = self.yearweek(previous_year,previous_week)
    
      
        total = (week_stats[current_key_string] ? week_stats[current_key_string] : 0)
        previous_week = (week_stats[previous_week_key_string] ? week_stats[previous_week_key_string] : 0)        
        previous_year = (week_stats[previous_year_key_string] ? week_stats[previous_year_key_string] : 0)        

        # pct_difference
        if((total + previous_week) == 0)
           pct_difference_week = 0
        else
           pct_difference_week = (total - previous_week) / ((total + previous_week) / 2)
        end   
        if((total + previous_year) == 0)
           pct_difference_year = 0
        else
           pct_difference_year = (total - previous_year) / ((total + previous_year) / 2)
        end
        # pct_change
        if(previous_week == 0)
          pct_change_week = 'NULL'
        else
          pct_change_week = (total - previous_week) / previous_week
        end
        if(previous_year == 0)
          pct_change_year = 'NULL'
        else
          pct_change_year = (total - previous_year) / previous_year
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
        insert_list << ActiveRecord::Base.quote_value(options[:metric])
        insert_list << self.yearweek(year,week)
        insert_list << year
        insert_list << week
        insert_list << ActiveRecord::Base.quote_value(self.year_week_date(year,week))
        insert_list << total
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
      self.order('yearweek').each do |ld|
        weekcount += 1
        running_total += ld.total
        rolling_data << [ld.yearweek_date,(running_total / weekcount)]
        value_data << [ld.yearweek_date,ld.total]
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
