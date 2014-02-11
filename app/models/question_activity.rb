# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class QuestionActivity < ActiveRecord::Base
  include CacheTools
  extend YearWeek

## constants
  ASSIGNED_TO = 1
  RESOLVED = 2
  REACTIVATE = 5
  REJECTED = 6
  NO_ANSWER = 7
  TAG_CHANGE = 8
  WORKING_ON = 9
  EDIT_QUESTION = 10
  PUBLIC_RESPONSE = 11
  REOPEN = 12
  CLOSED = 13
  INTERNAL_COMMENT = 14
  ASSIGNED_TO_GROUP = 15
  CHANGED_GROUP = 16
  CHANGED_LOCATION = 17


  YEARWEEK_ACTIVE = "YEARWEEK(#{self.table_name}.activity_at,3)"

  belongs_to :question
  belongs_to :contributor

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    insert_values = []
    AaeQuestionEvent.includes(:initiator).find_in_batches(:batch_size => 100) do |question_event_group|
      insert_values = []
      question_event_group.each do |qe|
        insert_list = []
        contributor = qe.initiator
        next if(contributor.nil? or contributor.id == 1 or !contributor.has_exid?)
        insert_list << qe.id
        insert_list << contributor.darmok_id
        insert_list << qe.question_id
        insert_list << qe.event_state
        insert_list << (AaeQuestionEvent::EVENT_TO_TEXT_MAPPING[qe.event_state].nil? ? 'NULL' : ActiveRecord::Base.quote_value(AaeQuestionEvent::EVENT_TO_TEXT_MAPPING[qe.event_state]))       
        insert_list << ActiveRecord::Base.quote_value(qe.created_at.utc.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end # question_group
      columns = self.column_names
      insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end # all questions
  end


  def self.increase_group_concat_length
    set_group_concat_size_query = "SET SESSION group_concat_max_len = #{Settings.group_concat_max_len};"
    self.connection.execute(set_group_concat_size_query)
  end

  def self.earliest_activity_at
    with_scope do
      ea = self.minimum(:activity_at)
      (ea < EpochDate::WWW_LAUNCH) ? EpochDate::WWW_LAUNCH : ea
    end
  end

  def self.latest_activity_at
    with_scope do
      self.maximum(:activity_at)
    end
  end

  def self.stats_by_yearweek(cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__,{scope_sql: current_scope ? current_scope.to_sql : ''})
      Rails.cache.fetch(cache_key,cache_options) do
        with_scope do
          _stats_by_yearweek(cache_options)
        end
      end
    else
      with_scope do
        _stats_by_yearweek(cache_options)
      end
    end
  end

  def self._stats_by_yearweek(cache_options = {})
    metric = 'experts'
    stats = YearWeekStats.new
    # increase_group_concat_length
    with_scope do
      ea = self.earliest_activity_at
      if(ea.blank?)
        return stats
      end
      la = self.latest_activity_at - 1.week

      metric_by_yearweek = self.group(YEARWEEK_ACTIVE).count('DISTINCT(contributor_id)')

      year_weeks = self.year_weeks_between_dates(ea.to_date,la.to_date)
      year_weeks.each do |year,week|
        yw = self.yearweek(year,week)
        stats[yw] = {}
        metric_value = metric_by_yearweek[yw] || 0
        stats[yw][metric] = metric_value

        previous_year_key = self.yearweek(year-1,week)
        (previous_year,previous_week) = self.previous_year_week(year,week)
        previous_week_key = self.yearweek(previous_year,previous_week)

        previous_week = (metric_by_yearweek[previous_week_key]  ? metric_by_yearweek[previous_week_key] : 0)
        stats[yw]["previous_week_#{metric}"] = previous_week
        previous_year = (metric_by_yearweek[previous_year_key]  ? metric_by_yearweek[previous_year_key] : 0)
        stats[yw]["previous_year_#{metric}"] = previous_year

        # pct_change
        if(previous_week == 0)
          stats[yw]["pct_change_week_#{metric}"] = nil
        else
          stats[yw]["pct_change_week_#{metric}"] = (metric_value - previous_week) / previous_week.to_f
        end

        if(previous_year == 0)
          stats[yw]["pct_change_year_#{metric}"] = nil
        else
          stats[yw]["pct_change_year_#{metric}"] = (metric_value - previous_year) / previous_year.to_f
        end
      end
    end
    stats
  end  

end
