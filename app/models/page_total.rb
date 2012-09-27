# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class PageTotal < ActiveRecord::Base
  belongs_to :page
  has_many :groups, :through => :page


  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    rebuild_for_metric('unique_pageviews')
  end

  def self.rebuild_for_metric(metric)
    return false if metric.nil?
    latest_yearweek = Analytic.latest_yearweek

    Page.find_in_batches do |group_of_pages|
      insert_values = []
      group_of_pages.each do |page|
        insert_list = []
        insert_list << page.id
        insert_list << ActiveRecord::Base.quote_value(metric)
        eligible_weeks = page.eligible_weeks(true)
        insert_list << eligible_weeks
        stats_by_yearweek = page.stats_by_yearweek(metric,{nocache: true})
        if !stats_by_yearweek.blank?
          total = stats_by_yearweek.sum_for_hashvalue('total')
          seen_weeks =  stats_by_yearweek.count_for_hashvalue('seen',1)
          mean = ( (eligible_weeks > 0) ? total / eligible_weeks.to_f : 'NULL')
          insert_list << total
          insert_list << seen_weeks
          insert_list << mean
          insert_list << latest_yearweek
          ['total','previous_week','previous_year','pct_change_week','pct_change_year'].each do |value|
            if(!stats_by_yearweek[latest_yearweek] or stats_by_yearweek[latest_yearweek][value].nil?)
              insert_list << 'NULL'
            else
              insert_list << stats_by_yearweek[latest_yearweek][value]
            end
          end
          (max_yearweek,max) = stats_by_yearweek.max_yearweek_for_hashvalue('total')
          insert_list << (max.nil? ? 'NULL' : max)
          insert_list << (max_yearweek.nil? ? 'NULL' : max_yearweek)
        else
          1.upto 11 do
            insert_list << 'NULL'
          end
        end
        insert_list << 'NOW()'
        insert_values << "(#{insert_list.join(',')})"
      end
      if(!insert_values.blank?)
        columns = self.column_names.reject{|n| n == "id"}
        insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
        self.connection.execute(insert_sql)
      end
    end
    true
  end

end