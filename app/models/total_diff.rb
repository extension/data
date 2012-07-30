# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class TotalDiff < ActiveRecord::Base
  belongs_to :group
  extend YearWeek
  
  
  scope :by_year_week, lambda {|year,week| where(:year => year).where(:week => week) }
  scope :by_datatype, lambda{|datatype| where(:datatype => datatype)}
  scope :overall, where(:group_id => 0)
  
  
  def self.max_views(nearest = nil)
    with_scope do
      max = maximum(:views)
      if(nearest)
        max = max + nearest - (max % nearest)
      end
    end
  end
  
  def self.rebuild
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    self.rebuild_by_datatype
    Group.launched.each do |group|
      self.rebuild_by_datatype(:group => group)
    end
  end
  
  
  def self.rebuild_by_datatype(options = {})
    
    datatypes = Page::DATATYPES
    group = options[:group]
    if(group.nil?)
      group_id = 0
      week_stats = WeekStat.sum_upv_by_yearweek_by_datatype
    else
      group_id = group.id
      week_stats = group.week_stats.sum_upv_by_yearweek_by_datatype
    end
    
    week_stats_by_yearweek = {}
    week_stats.each do |ws|
      key_string = "#{ws.year}-#{ws.week}-#{ws.datatype}"
      week_stats_by_yearweek[key_string] = ws.unique_pageviews
    end
    
    insert_values = []
    datatypes.each do |datatype|
      earliest_created_at = ((group.nil?) ? Page.by_datatype(datatype).minimum(:created_at) : group.pages.by_datatype(datatype).minimum(:created_at))
      if(!earliest_created_at.nil?)
        start_date = earliest_created_at.to_date
        yearweeks = Analytic.year_weeks_from_date(start_date)
      
      
        pagecounts = (group.nil?) ? Page.by_datatype(datatype).page_counts_by_yearweek : group.pages.by_datatype(datatype).page_counts_by_yearweek
      
        running_change = []
        running_difference = []
      
        yearweeks.each do |year,week|
        
          current_key_string = "#{year}-#{week}-#{datatype}"
          previous_year_key_string ="#{year-1}-#{week}-#{datatype}"
          (previous_year,previous_week) = Analytic.previous_year_week(year,week)
          previous_week_key_string = "#{previous_year}-#{previous_week}-#{datatype}"
    
    
          pages = pagecounts.select{|yearweek,count| yearweek <= self.yearweek(year,week)}.values.sum
          pages_previous_week = pagecounts.select{|yearweek,count| yearweek <= self.yearweek(previous_year,previous_week)}.values.sum  
          pages_previous_year = pagecounts.select{|yearweek,count| yearweek <= self.yearweek(previous_year-1,week)}.values.sum  
        
          total_views = (week_stats_by_yearweek[current_key_string] ? week_stats_by_yearweek[current_key_string] : 0)
          total_views_previous_week = (week_stats_by_yearweek[previous_week_key_string] ? week_stats_by_yearweek[previous_week_key_string] : 0)        
          total_views_previous_year = (week_stats_by_yearweek[previous_year_key_string] ? week_stats_by_yearweek[previous_year_key_string] : 0)        

          views = ((pages == 0) ? 0 : (total_views / pages))
          views_previous_week = ((pages_previous_week == 0) ? 0 : (total_views_previous_week / pages_previous_week))
          views_previous_year = ((pages_previous_year == 0) ? 0 : (total_views_previous_year / pages_previous_year))

          # pct_difference
          if((views + views_previous_week) == 0)
             pct_difference_week = 0
          else
             pct_difference_week = (views - views_previous_week) / ((views + views_previous_week) / 2)
          end   
          if((views + views_previous_year) == 0)
             pct_difference_year = 0
          else
             pct_difference_year = (views - views_previous_year) / ((views + views_previous_year) / 2)
          end
          # pct_change
          if(views_previous_week == 0)
            pct_change_week = 'NULL'
          else
            pct_change_week = (views - views_previous_week) / views_previous_week
          end
          if(views_previous_year == 0)
            pct_change_year = 'NULL'
          else
            pct_change_year = (views - views_previous_year) / views_previous_year
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
          insert_list << ActiveRecord::Base.quote_value(datatype)
          insert_list << self.yearweek(year,week)
          insert_list << year
          insert_list << week
          insert_list << ActiveRecord::Base.quote_value(self.year_week_date(year,week))
          insert_list << pages
          insert_list << pages_previous_week
          insert_list << pages_previous_year
          insert_list << total_views
          insert_list << total_views_previous_week
          insert_list << total_views_previous_year
          insert_list << views
          insert_list << views_previous_week
          insert_list << views_previous_year
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
    end # datatypes    
    if(!insert_values.blank?)
      columns = self.column_names.reject{|n| n == "id"}
      insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end      
  end
  
  
  def self.panda_impacts(panda_comparison_weeks = 3)
    panda_epoch_date = EpochDate.panda_epoch_date
    prior_panda_yearweeks = panda_epoch_date.previous_yearweeks(panda_comparison_weeks)
    post_panda_yearweeks =  panda_epoch_date.next_yearweeks(panda_comparison_weeks)
    
    post_panda_prior_yearweeks = []
    post_panda_year_weeks = panda_epoch_date.next_year_weeks(panda_comparison_weeks)
    post_panda_year_weeks.each do |year,week|
      post_panda_prior_yearweeks << EpochDate.yearweek(year-1,week)
    end
    
    prior_diffs = TotalDiff.where("yearweek IN (#{prior_panda_yearweeks.join(',')})").group("group_id,datatype").select("group_id,datatype,SUM(views) as sum_views")
    post_diffs = TotalDiff.where("yearweek IN (#{post_panda_yearweeks.join(',')})").group("group_id,datatype").select("group_id,datatype,SUM(views) as sum_views")
    post_diffs_prior_year = TotalDiff.where("yearweek IN (#{post_panda_prior_yearweeks.join(',')})").group("group_id,datatype").select("group_id,datatype,SUM(views) as sum_views")
      
    prior_views = {}
    prior_diffs.each do |pd|
      prior_views[pd.group_id] ||= {}
      prior_views[pd.group_id][pd.datatype] = (pd.sum_views / panda_comparison_weeks)
    end
    
    post_views = {}
    post_diffs.each do |pd|
      post_views[pd.group_id] ||= {}
      post_views[pd.group_id][pd.datatype] = (pd.sum_views / panda_comparison_weeks)
    end
    
    post_views_prior_year = {}
    post_diffs_prior_year.each do |pd|
      post_views_prior_year[pd.group_id] ||= {}
      post_views_prior_year[pd.group_id][pd.datatype] = (pd.sum_views / panda_comparison_weeks)
    end
    
    
    
    views_change_by_group = {}
    post_views.each do |group_id,data|
      views_change_by_group[group_id] ||= {}
      
      Page::DATATYPES.each do |datatype|
        post_view_count =  (data[datatype].nil? ? nil : data[datatype])
        if(prior_views[group_id])
          prior_view_count =  (prior_views[group_id][datatype].nil? ? nil : prior_views[group_id][datatype])
        end
        
        if(post_views_prior_year[group_id])
          post_view_prior_year_count =  (post_views_prior_year[group_id][datatype].nil? ? nil : post_views_prior_year[group_id][datatype])
        end
        
        
          
        raw_change = 'n/a'
        pct_change = 'n/a'
        
        raw_change_year = 'n/a'
        pct_change_year = 'n/a'
        
      
        if((!prior_view_count.nil? and  (prior_view_count > 0)) and !post_view_count.nil?)
          raw_change = (post_view_count - prior_view_count)
          pct_change = raw_change / prior_view_count
        end
        
        if((!post_view_prior_year_count.nil? and  (post_view_prior_year_count > 0)) and !post_view_count.nil?)
          raw_change_year = (post_view_count - post_view_prior_year_count)
          pct_change_year = raw_change_year / post_view_prior_year_count
        end
        
        
        views_change_by_group[group_id][datatype] = {:raw_change => raw_change, :pct_change => pct_change, :raw_change_year => raw_change_year, :pct_change_year => pct_change_year}
      end   
    end
    views_change_by_group    
  end

  

  
  
end
