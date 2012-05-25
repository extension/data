# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class TotalDiff < ActiveRecord::Base
  belongs_to :resource_tag
  
  
  def self.rebuild_all
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    self.rebuild_by_datatype
    ResourceTag.all.each do |tag|
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
    yearweeks = WeekStat.year_weeks_from_date(start_date)
    datatypes.each do |datatype|
      yearweeks.each do |year,week|
        
        key_string = "#{year}-#{week}-#{datatype}"
        (previous_year,previous_week) = WeekStat.previous_yearweek(year,week)
        previous_key_string = "#{previous_year}-#{previous_week}-#{datatype}"
    
        pages = (tag.nil?) ? Page.by_datatype(datatype).pagecount_for_yearweek(year,week) : tag.pages.by_datatype(datatype).pagecount_for_yearweek(year,week)
        previous_pages = (tag.nil?) ? Page.by_datatype(datatype).pagecount_for_yearweek(previous_year,previous_week) : tag.pages.by_datatype(datatype).pagecount_for_yearweek(previous_year,previous_week)
    
        
        previous_upv = (week_stats_by_yearweek[previous_key_string] ? week_stats_by_yearweek[previous_key_string] : 0)        
        current_upv = (week_stats_by_yearweek[key_string] ? week_stats_by_yearweek[key_string] : 0)
        
        previous_avg_upv = (previous_pages == 0) ? 0 : (previous_upv / previous_pages)
        current_avg_upv = (pages == 0) ? 0 : (current_upv / pages)
      
        
        insert_list = []
        insert_list << tag_id
        insert_list << ActiveRecord::Base.quote_value(datatype)
        insert_list << year
        insert_list << week
        insert_list << ActiveRecord::Base.quote_value(Date.commercial(year,week,7))
        insert_list << previous_pages
        insert_list << pages
        insert_list << previous_upv
        insert_list << current_upv
        # pct_upv_difference
        if((current_upv + previous_upv) == 0)
          insert_list << 0
        else
          insert_list << (current_upv - previous_upv) / ((current_upv + previous_upv) / 2)
        end
        # pct_upv_change
        if(previous_upv == 0)
          insert_list << 'NULL'
        else
          insert_list << (current_upv - previous_upv) / previous_upv
        end
        
        insert_list << previous_avg_upv
        insert_list << current_avg_upv
        
        
        # pct_avg_upv_difference
        if((current_avg_upv + previous_avg_upv) == 0)
          insert_list << 0
        else
          
          insert_list << (current_avg_upv - previous_avg_upv) / ((current_avg_upv + previous_avg_upv) / 2)
        end
        # pct_avg_upv_change
        if(previous_avg_upv == 0)
          insert_list << 'NULL'
        else
          insert_list << (current_avg_upv - previous_avg_upv) / previous_avg_upv
        end
            
        
        insert_list << 'NOW()'
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
  
end
