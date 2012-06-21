# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class TotalDiff < ActiveRecord::Base
  belongs_to :tag
  extend YearWeek
  
  
  
  
  
  def self.rebuild_all
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    self.rebuild_by_datatype
    Tag.grouptags.all.each do |tag|
      self.rebuild_by_datatype(:tag => tag)
    end
  end
  
  
  def self.rebuild_by_datatype(options = {})
    
    datatypes = Page.datatypes
    tag = options[:tag]
    if(tag.nil?)
      tag_id = 0
      week_stats = WeekStat.sum_upv_by_yearweek_by_datatype
    else
      tag_id = tag.id
      week_stats = tag.week_stats.sum_upv_by_yearweek_by_datatype
    end
    
    week_stats_by_yearweek = {}
    week_stats.each do |ws|
      key_string = "#{ws.year}-#{ws.week}-#{ws.datatype}"
      week_stats_by_yearweek[key_string] = ws.unique_pageviews
    end
    
    insert_values = []
    start_date = Page.minimum(:created_at).to_date
    yearweeks = Analytic.year_weeks_from_date(start_date)
    datatypes.each do |datatype|
      
      pagecounts = (tag.nil?) ? Page.by_datatype(datatype).page_counts_by_yearweek : tag.pages.by_datatype(datatype).page_counts_by_yearweek
      
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

        views = (pages == 0) ? 0 : (total_views / pages)
        views_previous_week = (pages_previous_week == 0) ? 0 : (total_views_previous_week / pages_previous_week)
        views_previous_year = (pages_previous_year == 0) ? 0 : (total_views_previous_year / pages_previous_year)

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
              
        insert_list = []
        insert_list << tag_id
        insert_list << ActiveRecord::Base.quote_value(datatype)
        insert_list << self.yearweek(year,week)
        insert_list << year
        insert_list << week
        insert_list << ActiveRecord::Base.quote_value(Date.commercial(year,week,7))
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
        insert_list << pct_change_week
        insert_list << pct_change_year
        insert_list << 'NOW()'        
        insert_values << "(#{insert_list.join(',')})"
      end # year-week
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
    prior_diffs = TotalDiff.where("yearweek IN (#{prior_panda_yearweeks.join(',')})").group("tag_id,datatype").select("tag_id,datatype,SUM(views) as sum_views")
    post_diffs = TotalDiff.where("yearweek IN (#{post_panda_yearweeks.join(',')})").group("tag_id,datatype").select("tag_id,datatype,SUM(views) as sum_views")
      
    prior_views = {}
    prior_diffs.each do |pd|
      prior_views[pd.tag_id] ||= {}
      prior_views[pd.tag_id][pd.datatype] = (pd.sum_views / panda_comparison_weeks)
    end
    
    post_views = {}
    post_diffs.each do |pd|
      post_views[pd.tag_id] ||= {}
      post_views[pd.tag_id][pd.datatype] = (pd.sum_views / panda_comparison_weeks)
    end
    
    
    views_change_by_tag = {}
    prior_views.each do |tag_id,data|
      views_change_by_tag[tag_id] ||= {}
      
      Page::DATATYPES.each do |datatype|
        prior_view_count =  (data[datatype].nil? ? nil : data[datatype])
        if(post_views[tag_id])
          post_view_count =  (post_views[tag_id][datatype].nil? ? nil : post_views[tag_id][datatype])
        end
          
        raw_change = 'n/a'
        pct_change = 'n/a'
      
        if((!prior_view_count.nil? and  (prior_view_count > 0)) and !post_view_count.nil?)
          raw_change = (post_view_count - prior_view_count)
          pct_change = raw_change / prior_view_count
        end
        
        views_change_by_tag[tag_id][datatype] = {:raw_change => raw_change, :pct_change => pct_change}
      end   
    end
    views_change_by_tag    
  end
  
end
