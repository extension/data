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
    self.rebuild_by_group(:group => 'overall')
    Group.launched.each do |group|
      self.rebuild_by_group(:group => group)
    end
  end
  
  
  def self.rebuild_by_group(options = {})
    
    datatypes = Page.datatypes
    group = options[:group]  
    if(group.nil? or group == 'overall')
      group = nil
      group_id = 0
    else
      group_id = group.id
    end
    
    earliest_created_at = ((group.nil?) ? Page.minimum(:created_at) : group.pages.minimum(:created_at))
    if(!earliest_created_at.nil?)
      start_date = earliest_created_at.to_date
    
      yearweeks = Analytic.year_weeks_from_date(start_date)
      datatypes.each do |datatype|
        insert_values = []
        percentiles_by_yearweek = (group.nil?) ? Page.by_datatype(datatype).percentiles   : group.pages.by_datatype(datatype).percentiles  
        yearweeks.each do |year,week|
          yearweek = self.yearweek(year,week)
          percentiles = (percentiles_by_yearweek[yearweek] || {})
          insert_list = []
          insert_list << group_id
          insert_list << ActiveRecord::Base.quote_value(datatype)
          insert_list << yearweek
          insert_list << year
          insert_list << week
          insert_list << ActiveRecord::Base.quote_value(Date.commercial(year,week,7))
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
        if(!insert_values.blank?)
          columns = self.column_names.reject{|n| n == "id"}
          insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
          self.connection.execute(insert_sql)
        end    
      end # datatypes
    end # nil? check for created_at      
  end
  


end