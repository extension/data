# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Percentile < ActiveRecord::Base
  belongs_to :group
  extend YearWeek

  scope :by_datatype, lambda{|datatype| where(:datatype => datatype)}
  scope :overall, where(:group_id => 0)
  
  TRACKED = [99,95,90,75,50,25,10]

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
    
    datatypes.each do |datatype|
      earliest_created_at = ((group.nil?) ? Page.by_datatype(datatype).minimum(:created_at) : group.pages.by_datatype(datatype).minimum(:created_at))
      if(!earliest_created_at.nil?)
        start_date = earliest_created_at.to_date
        yearweeks = Analytic.year_weeks_from_date(start_date)
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
          insert_list << ActiveRecord::Base.quote_value(self.yearweek_date(year,week))
          insert_list << (percentiles[:total] || 'NULL')
          insert_list << (percentiles[:seen] || 'NULL')
          TRACKED.each do |pct|
            insert_list << (percentiles[pct] || 'NULL')
          end
          insert_list << 'NOW()'        
          insert_values << "(#{insert_list.join(',')})"
        end # year-week
        if(!insert_values.blank?)
          columns = self.column_names.reject{|n| n == "id"}
          insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
          self.connection.execute(insert_sql)
        end
      end # nil? check for created_at            
    end # datatypes
  end
  
  def self.overall_percentile_data_by_datatype(datatype)
    returndata = {}
    week_stats = {}
    self.by_datatype(datatype).overall.order('yearweek').map do |percentiles|
      yearweek_string = "#{percentiles.year}-" + "%02d" % percentiles.week 
      week_stats[yearweek_string] = {}
      TRACKED.each do |pct|
        column_name = "pct_#{pct}"
        week_stats[yearweek_string][pct] = percentiles.send(column_name)
      end
    end
    
    start_date = Page.by_datatype(datatype).minimum(:created_at).to_date
    year_weeks = Analytic.year_weeks_from_date(start_date)
    year_weeks.each do |year,week|
      yearweek_string = "#{year}-" + "%02d" % week
      date = self.yearweek_date(year,week)
      TRACKED.each do |pct|
        returndata[pct] ||= []
        if(week_stats[yearweek_string].nil?)
          views = 0
        elsif(week_stats[yearweek_string][pct].nil?)
          views = 0
        else
          views = week_stats[yearweek_string][pct]
        end        
        returndata[pct] << [date,views]
      end
    end
    returndata
  end  
  
  


end