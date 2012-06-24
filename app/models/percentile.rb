# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Percentile < ActiveRecord::Base
  belongs_to :group
  extend YearWeek

  def self.rebuild
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    self.rebuild_by_datatype
    Group.launched.each do |group|
      self.rebuild_by_datatype(:group => group)
    end
  end
  
  
  def self.rebuild_by_datatype(options = {})
    
    datatypes = Page.datatypes
    group = options[:group]  
    if(group.nil?)
      group_id = 0
    else
      group_id = group.id
    end
    
    insert_values = []
    start_date = Page.minimum(:created_at).to_date
    yearweeks = Analytic.year_weeks_from_date(start_date)
    datatypes.each do |datatype|      
      yearweeks.each do |year,week|
        percentiles = (group.nil?) ? Page.by_datatype(datatype).percentiles_for_year_week(year,week) : group.pages.by_datatype(datatype).percentiles_for_year_week(year,week)
        insert_list = []
        insert_list << group_id
        insert_list << ActiveRecord::Base.quote_value(datatype)
        insert_list << self.yearweek(year,week)
        insert_list << year
        insert_list << week
        insert_list << (percentiles[:total] || 'NULL')
        insert_list << (percentiles[:seen] || 'NULL')
        insert_list << (percentiles[99] || 'NULL')
        insert_list << (percentiles[95] || 'NULL')
        insert_list << (percentiles[90] || 'NULL')
        insert_list << (percentiles[75] || 'NULL')
        insert_list << (percentiles[50] || 'NULL')
        insert_list << (percentiles[25] || 'NULL')
        insert_list << (percentiles[10] || 'NULL')
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