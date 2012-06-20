# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class PageDiff < ActiveRecord::Base
  belongs_to :page
  extend YearWeek
  
  
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
      page.eligible_year_weeks.each do |year,week|
        
        current_key_string = "#{year}-#{week}"
        previous_year_key_string ="#{year-1}-#{week}"
        (previous_year,previous_week) = Analytic.previous_year_week(year,week)
        previous_week_key_string = "#{previous_year}-#{previous_week}"
        
        
        views_previous_year = (week_stats_by_yearweek[previous_year_key_string] ? week_stats_by_yearweek[previous_year_key_string] : 0)
        views_previous_week = (week_stats_by_yearweek[previous_week_key_string] ? week_stats_by_yearweek[previous_week_key_string] : 0)
        views = (week_stats_by_yearweek[current_key_string] ? week_stats_by_yearweek[current_key_string] : 0)
      
        insert_list = []
        insert_list << page.id
        insert_list << self.yearweek(year,week)
        insert_list << year
        insert_list << week
        insert_list << views
        insert_list << views_previous_week
        insert_list << views_previous_year
        # pct_difference
        if((views + views_previous_week) == 0)
           insert_list << 0
        else
           insert_list << (views - views_previous_week) / ((views + views_previous_week) / 2)
        end   
        if((views + views_previous_year) == 0)
           insert_list << 0
        else
           insert_list << (views - views_previous_year) / ((views + views_previous_year) / 2)
        end
        # pct_change
        if(views_previous_week == 0)
          insert_list << 'NULL'
        else
          insert_list << (views - views_previous_week) / views_previous_week
        end
        if(views_previous_year == 0)
          insert_list << 'NULL'
        else
          insert_list << (views - views_previous_year) / views_previous_year
        end
        insert_list << 'NOW()'
        insert_values << "(#{insert_list.join(',')})"
      end
      if(!insert_values.blank?)
        columns = self.column_names.reject{|n| n == "id"}
        insert_sql = "INSERT INTO #{self.table_name}  (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
        self.connection.execute(insert_sql)
      end
    end
  end
  
  
    
end
