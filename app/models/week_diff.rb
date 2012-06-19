# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class WeekDiff < ActiveRecord::Base
  belongs_to :page
  
  
  def self.rebuild
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    Page.find_each do |page|
      week_stats = page.week_stats
      week_stats_by_yearweek = {}
      page.week_stats.each do |ws|
        key_string = "#{ws.year}-#{ws.week}"
        week_stats_by_yearweek[key_string] = ws.unique_pageviews
      end
      
      insert_values = []
      page.eligible_yearweeks.each do |year,week|
        key_string = "#{year}-#{week}"
        (previous_year,previous_week) = Analytic.previous_year_week(year,week)
        previous_key_string = "#{previous_year}-#{previous_week}"
    
        previous_upv = (week_stats_by_yearweek[previous_key_string] ? week_stats_by_yearweek[previous_key_string] : 0)
        current_upv = (week_stats_by_yearweek[key_string] ? week_stats_by_yearweek[key_string] : 0)
      
        
        insert_list = []
        insert_list << page.id
        insert_list << year
        insert_list << week
        insert_list << previous_upv
        insert_list << current_upv
        if((current_upv + previous_upv) == 0)
          insert_list << 0
        else
          insert_list << (current_upv - previous_upv) / ((current_upv + previous_upv) / 2)
        end
        if(previous_upv == 0)
          insert_list << 'NULL'
        else
          insert_list << (current_upv - previous_upv) / previous_upv
        end
        insert_list << 'NOW()'
        insert_list << 'NOW()'
        
        insert_values << "(#{insert_list.join(',')})"
      end
      if(!insert_values.blank?)
        insert_sql = "INSERT INTO #{self.table_name} (page_id,year,week,previous_upv,current_upv,pct_difference,pct_change,created_at,updated_at) VALUES #{insert_values.join(',')};"
        self.connection.execute(insert_sql)
      end
    end
  end
  
  
    
end
