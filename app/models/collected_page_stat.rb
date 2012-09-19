# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class CollectedPageStat < ActiveRecord::Base
  extend YearWeek
  belongs_to :statable, polymorphic: true

  def self.rebuild
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    self.rebuild_for_statable_metric({metric: 'unique_pageviews'})

    # Group.launched.each do |group|
    #   self.rebuild_by_datatype(:group => group)
    # end
  end

  def self.rebuild_for_statable_metric(options = {})
    statable_object = options[:statable_object]
    metric = options[:metric]
    return false if metric.nil?

    if(statable_object.nil?)
      statable_id = 0
      statable_type = 'Page'
      scope = Page
    else
      statable_id = 0
      statable_type = statable_object.class.name
      scope = statable_object.pages
    end

    datatypes = Page::DATATYPES
    datatypes.each do |datatype|
      insert_values = []
      stats = scope.by_datatype(datatype).stats_by_yearweek(metric,{force: true})
      stats.keys.sort.each do |yearweek|
        insert_list = []
        insert_list << statable_id
        insert_list << ActiveRecord::Base.quote_value(statable_type)
        insert_list << ActiveRecord::Base.quote_value(datatype)
        insert_list << ActiveRecord::Base.quote_value(metric)
        insert_list << yearweek
        (year,week) = self.yearweek_year_week(yearweek)
        insert_list << year
        insert_list << week
        insert_list << ActiveRecord::Base.quote_value(self.year_week_date(year,week))
        ['pages','seen','total','per_page','per_page_rolling','previous_week','previous_year','pct_change_week','pct_change_year'].each do |value|
          if(stats[yearweek][value].nil?)
            insert_list << 'NULL'
          else
            insert_list << stats[yearweek][value]
          end
        end
        insert_list << 'NOW()'        
        insert_values << "(#{insert_list.join(',')})"
      end # yearweek loop
      if(!insert_values.blank?)
        columns = self.column_names.reject{|n| n == "id"}
        insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
        self.connection.execute(insert_sql)
      end 
    end # datatype loop
    true
  end

end

