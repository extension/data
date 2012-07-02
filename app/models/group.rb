# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Group < ActiveRecord::Base
  extend YearWeek
  has_many :node_groups
  has_many :nodes, :through => :node_groups
  has_many :tags
  has_many :pages, :through => :tags
  has_many :analytics, :through => :tags
  has_many :week_stats, :through => :tags  
  has_many :total_diffs
  has_many :percentiles
  
  scope :launched, where(:is_launched => true)  
  
  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};") 
    insert_values = []   
    DarmokCommunity.where("drupal_node_id IS NOT NULL").each do |group|
      insert_list = []
      insert_list << group.id
      insert_list << group.drupal_node_id
      insert_list << ActiveRecord::Base.quote_value(group.name)
      insert_list << group.is_launched
      insert_list << ActiveRecord::Base.quote_value(group.created_at.to_s(:db))
      insert_list << ActiveRecord::Base.quote_value(group.updated_at.to_s(:db))
      insert_values << "(#{insert_list.join(',')})"
    end
    insert_sql = "INSERT INTO #{self.table_name} VALUES #{insert_values.join(',')};"
    self.connection.execute(insert_sql)
  end
  
  
  def stats_for_week_for_datatype(datatype)
    returndata = {}
    (year,week) = Analytic.latest_year_week
    td = self.total_diffs.by_datatype(datatype).by_year_week(year,week).first
    if(td.nil?)
      pages = self.pages.by_datatype(datatype).count
      new_pages = 'unknown'
      views = 0
      change_week = nil
      change_year = nil
    else
      pages = td.pages
      views = td.views
      change_week = td.pct_change_week
      change_year = td.pct_change_year
      recent = td.recent_pct_change.nil? ? nil : td.recent_pct_change / Settings.recent_weeks
      new_pages = td.pages - td.pages_previous_week
    end
    average = self.total_diffs.by_datatype(datatype).average(:views)
    weeks = self.total_diffs.by_datatype(datatype).count
    
    pctile = self.percentiles.by_datatype(datatype).by_year_week(year,week).first
    
    returndata[:pages] = pages
    returndata[:new_pages] = new_pages
    returndata[:views] =  views

    returndata[:change_week] = change_week
    returndata[:change_year] = change_year
    returndata[:recent_change] = recent
    returndata[:average] = average
    returndata[:weeks] = weeks
    if(!pctile.nil?)
      returndata[:seen] = pctile.seen || 0
      Percentile::TRACKED.each do |pct|
        column_name = "pct_#{pct}"
        returndata[column_name.to_sym] = pctile.send(column_name)
      end
    else
      returndata[:seen] = 0
    end
      
    returndata
  end
  
  def traffic_stats_data_by_datatype(datatype)
    returndata = []
    week_stats = {}
    self.total_diffs.by_datatype(datatype).order('yearweek').map do |ws|
      yearweek_string = "#{ws.year}-" + "%02d" % ws.week 
      week_stats[yearweek_string] = ws.views
    end
    
    earliest_created_at = self.pages.by_datatype(datatype).minimum(:created_at)
    if(!earliest_created_at.nil?)
      start_date =  earliest_created_at.to_date   
      year_weeks = Analytic.year_weeks_from_date(start_date)
      year_weeks.each do |year,week|
        yearweek_string = "#{year}-" + "%02d" % week
        date = self.class.yearweek_date(year,week)
        upv = week_stats[yearweek_string].nil? ? 0 : week_stats[yearweek_string]
        returndata << [date,upv]
      end
      returndata
    else
      []
    end
  end
  
  
end