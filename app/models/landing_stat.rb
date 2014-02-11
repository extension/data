# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class LandingStat < ActiveRecord::Base
  include CacheTools
  extend YearWeek
  belongs_to :group

  scope :by_year_week, lambda {|year,week| where(:year => year).where(:week => week) }
  scope :overall, where(:group_id => 0)
  scope :by_metric, lambda{|metric| where(:metric => metric)}
  scope :latest_week, lambda{(year,week) = Analytic.latest_year_week; by_year_week(year,week)}


  def self.rebuild
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    self.rebuild_root
    Group.launched.each do |group|
      self.rebuild_group(group)
    end
    true
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

  def self.earliest_yearweek_date
    with_scope do
      self.minimum(:yearweek_date)
    end
  end

  def self.stats_by_yearweek(metric,cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__,{metric: metric, scope_sql: current_scope ? current_scope.to_sql : ''})
      Rails.cache.fetch(cache_key,cache_options) do
        with_scope do
          _stats_by_yearweek(metric)
        end
      end
    else
      with_scope do
        _stats_by_yearweek(metric)
      end
    end
  end

  def self._stats_by_yearweek(metric)
    stats = YearWeekStats.new
    with_scope do
      metric_by_yearweek = self.group(:yearweek).sum(metric)
      yearweeks = Analytic.year_weeks_from_date(self.earliest_yearweek_date)
      metric_totals  = 0
      loopcount = 0
      yearweeks.each do |year,week|
        loopcount += 1
        yearweek = self.yearweek(year,week)
        stats[yearweek] = {}
        total = metric_by_yearweek[yearweek] || 0
        stats[yearweek]['total'] = total
        metric_totals += total
        stats[yearweek]['rolling'] = metric_totals / loopcount

        previous_year_key = self.yearweek(year-1,week)
        (previous_year,previous_week) = self.previous_year_week(year,week)
        previous_week_key = self.yearweek(previous_year,previous_week)

        previous_week = (metric_by_yearweek[previous_week_key]  ? metric_by_yearweek[previous_week_key] : 0)
        stats[yearweek]['previous_week'] = previous_week
        previous_year = (metric_by_yearweek[previous_year_key]  ? metric_by_yearweek[previous_year_key] : 0)
        stats[yearweek]['previous_year'] = previous_year

        # pct_change
        if(previous_week == 0)
          stats[yearweek]['pct_change_week'] = nil
        else
          stats[yearweek]['pct_change_week'] = (total - previous_week) / previous_week
        end

        if(previous_year == 0)
          stats[yearweek]['pct_change_year'] = nil
        else
          stats[yearweek]['pct_change_year'] = (total - previous_year) / previous_year
        end
      end
    end
    stats
  end
end