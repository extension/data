# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class LandingStat < ActiveRecord::Base
  extend YearWeek
  belongs_to :group

  scope :overall, where(:group_id => 0)


  def self.rebuild
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    self.rebuild_root
    Group.launched.each do |group|
      self.rebuild_group(group)
    end
  end

  def self.rebuild_root
    # don't insert records earlier than first yearweek
    (e_year,e_week) = Page.earliest_year_week
    earliest_year_week_string = self.yearweek_string(e_year,e_week)
    select_statement = <<-END
    0,
    yearweek,
    year, 
    week,
    STR_TO_DATE(CONCAT(yearweek,' Sunday'), '%X%V %W'),
    SUM(pageviews) as pageviews, 
    SUM(entrances) as entrances, 
    SUM(unique_pageviews) as unique_pageviews, 
    SUM(time_on_page) as time_on_page, 
    SUM(exits) AS exits,
    SUM(visitors) AS visitors,
    SUM(new_visits) AS new_visits,
    NOW() as created_at,
    NOW() as updated_at
    END
    where_clause = "yearweek >= #{earliest_year_week_string} AND url_type = '#{Analytic::URL_ROOT}'"
    group_by = "yearweek"
    columns = self.column_names.reject{|n| n == "id"}
    insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) SELECT #{select_statement} FROM #{Analytic.table_name} WHERE #{where_clause} GROUP BY #{group_by};"
    self.connection.execute(insert_sql)
  end

  def self.rebuild_group(group)
    # don't insert records earlier than first yearweek
    earliest_created_at = group.pages.minimum(:created_at)
    if(earliest_created_at.nil?)
      return true
    end
    (e_year,e_week) = self.year_week_for_date(earliest_created_at.to_date)
    earliest_year_week_string = self.yearweek_string(e_year,e_week)
    select_statement = <<-END
    #{group.id},
    yearweek,
    year, 
    week,
    STR_TO_DATE(CONCAT(yearweek,' Sunday'), '%X%V %W'),
    SUM(pageviews) as pageviews, 
    SUM(entrances) as entrances, 
    SUM(unique_pageviews) as unique_pageviews, 
    SUM(time_on_page) as time_on_page, 
    SUM(exits) AS exits,
    SUM(visitors) AS visitors,
    SUM(new_visits) AS new_visits,
    NOW() as created_at,
    NOW() as updated_at
    END
    where_clause = "yearweek >= #{earliest_year_week_string} AND url_type = '#{Analytic::URL_LANDING}' AND tag_id IN (#{group.tags.map(&:id).join(',')})"
    group_by = "yearweek"
    columns = self.column_names.reject{|n| n == "id"}
    insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) SELECT #{select_statement} FROM #{Analytic.table_name} WHERE #{where_clause} GROUP BY #{group_by};"
    self.connection.execute(insert_sql)
  end


  def self.sum_metric_by_yearweek(metric)
    case metric
    when 'views'
      qcolumn = 'unique_pageviews'
    else
      qcolumn = 'metric'
    end        
    with_scope do
      group(:yearweek).sum(qcolumn)
    end
  end
end