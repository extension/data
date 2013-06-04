# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file
require 'csv'

class AaeQuestion < ActiveRecord::Base
  include CacheTools
  extend YearWeek

  # connects to the aae database
  self.establish_connection :aae
  self.table_name='questions'

## includes

## attributes

## constants

  # status numbers (for status_state)     
  STATUS_SUBMITTED = 1
  STATUS_RESOLVED = 2
  STATUS_NO_ANSWER = 3
  STATUS_REJECTED = 4
  STATUS_CLOSED = 5
  
  # status text (to be used when a text version of the status is needed)
  STATUS_TEXT = {
    STATUS_SUBMITTED => 'submitted',
    STATUS_RESOLVED => 'answered',
    STATUS_NO_ANSWER => 'not_answered',
    STATUS_REJECTED => 'rejected',
    STATUS_CLOSED => 'closed'
  }

  # reporting scopes
  YEARWEEK_SUBMITTED = 'YEARWEEK(questions.created_at,3)'

  AAE_V2_TRANSITION = '2012-12-03 12:00:00 UTC'
  DEMOGRAPHIC_ELIGIBLE = '2012-12-03 12:00:00 UTC'
  EVALUATION_ELIGIBLE = '2013-03-15 00:00:00 UTC' # beware the ides of March


## validations

## filters

## associations
  has_many :question_events, :class_name => 'AaeQuestionEvent', foreign_key: 'question_id'

  belongs_to :assignee, :class_name => "AaeUser", :foreign_key => "assignee_id"
  belongs_to :current_resolver, :class_name => "AaeUser", :foreign_key => "current_resolver_id"
  belongs_to :location, class_name: 'AaeLocation'
  belongs_to :county, class_name: 'AaeCounty'
  belongs_to :original_location, :class_name => "AaeLocation", :foreign_key => "original_location_id"
  belongs_to :original_county, :class_name => "AaeCounty", :foreign_key => "original_county_id"
  belongs_to :submitter, :class_name => "AaeUser", :foreign_key => "submitter_id"
  belongs_to :assigned_group, :class_name => "AaeGroup", :foreign_key => "assigned_group_id"
  belongs_to :original_group, :class_name => "AaeGroup", :foreign_key => "original_group_id"
  belongs_to :initial_response,  class_name: 'AaeResponse', :foreign_key => "initial_response_id"

  has_many :responses, class_name: 'AaeResponse', foreign_key: 'question_id'
  has_many :evaluation_answers, class_name: 'AaeEvaluationAnswer', foreign_key: 'question_id' 
  has_many :comments, class_name: 'AaeComment', foreign_key: 'question_id' 

## scopes
  scope :answered, where(:status_state => STATUS_RESOLVED)
  scope :submitted, where(:status_state => STATUS_SUBMITTED)
  scope :not_rejected, conditions: "status_state <> #{STATUS_REJECTED}"
  scope :since_changeover, where("created_at >= ?",Time.parse(AAE_V2_TRANSITION))
  scope :evaluation_eligible,  lambda{ where("#{self.table_name}.created_at > ?",Time.parse(EVALUATION_ELIGIBLE))
                                       .where(:evaluation_sent => true) }

  def to_ua_report
    returndata = []
    ua = UserAgent.parse(self.user_agent)
    returndata << self.id
    returndata << self.created_at.to_date.to_s
    returndata << self.created_at.to_i
    if(!self.user_agent.blank?)
      returndata << ua.browser
      returndata << ua.version
      returndata << ua.platform
      returndata << ua.mobile?
    else
      returndata << 'unknown'
      returndata << 'unknown'
      returndata << 'unknown'
      returndata << 'unknown'
    end
    if(!self.location.blank?)
      returndata << self.location.name
    else
      returndata << 'unknown'
    end
    returndata
  end

  def detected_location
    AaeLocation.find_by_geoip(self.user_ip)
  end

  def detected_county
    AaeCounty.find_by_geoip(self.user_ip)
  end

  def is_mobile?
    if(!self.user_agent.blank?)
      ua = UserAgent.parse(self.user_agent)
      ua.mobile?
    else
      nil
    end
  end

  def demographic_eligible?
    (self.created_at >= Time.parse(DEMOGRAPHIC_ELIGIBLE) && self.evaluation_sent?)
  end

  def evaluation_eligible?
    (self.created_at >= Time.parse(EVALUATION_ELIGIBLE) && self.evaluation_sent?)
  end


  def response_times
    self.responses.expert_after_public.pluck(:time_since_last)
  end

  def mean_response_time
    self.response_times.mean
  end

  def tags
    AaeTag.includes(:taggings).where('taggings.taggable_type = ?','Question').where('taggings.taggable_id = ?', self.id)
  end

  def aae_version
    (self.created_at >= Time.parse(AAE_V2_TRANSITION)) ? 2 : 1
  end

  def source
    if(self.aae_version == 1)
      (self.external_app_id == 'widget') ? 'widget' : 'website'
    else
      (self.referrer =~ %r{widget}) ? 'widget' : 'website'
    end
  end


  def self.ua_report(filename)
    CSV.open(filename, "wb") do |csv|
      csv << ['question_id','date','unixtime','browser','version','platform','mobile?','location']
      self.not_rejected.each do |question|
        if(!question.user_agent.blank?)
          csv << question.to_ua_report
        end
      end
    end
  end


  def self.evaluation_data_csv(filename)
    CSV.open(filename,'wb') do |csv|
      headers = []
      headers << 'question_id'
      headers << 'submitter_is_extension'
      headers << 'evaluation_count'
      eval_columns = []
      AaeEvaluationQuestion.order(:id).active.each do |aeq|
        eval_columns << "evaluation_#{aeq.id}_response"
        eval_columns << "evaluation_#{aeq.id}_value"
      end
      headers += eval_columns
      csv << headers

      # data
      # evaluation_answer_questions
      eligible_questions = Question.where(evaluation_eligible: true).pluck(:id)
      response_questions = AaeEvaluationAnswer.pluck(:question_id).uniq
      eligible_response_questions = eligible_questions & response_questions
      self.where("id in (#{eligible_response_questions.join(',')})").includes(:submitter).each do |question|
        eval_count = question.evaluation_answers.count
        next if (eval_count == 0)
        row = []
        row << question.id
        row << question.submitter.has_exid?
        row << eval_count
        question_data = {}
        question.evaluation_answers.each do |ea|
          question_data["evaluation_#{ea.evaluation_question_id}_response"] = ea.response
          question_data["evaluation_#{ea.evaluation_question_id}_value"] = ea.evaluation_question.reporting_response_value(ea.response)
        end

        eval_columns.each do |column|
          value = question_data[column]
          if(value.is_a?(Time))
            row << value.strftime("%Y-%m-%d %H:%M:%S")
          else
            row << value
          end
        end

        csv << row
      end 
    end
  end


  def self.name_or_nil(item)
    item.nil? ? nil : item.name
  end

  def self.increase_group_concat_length
    set_group_concat_size_query = "SET SESSION group_concat_max_len = #{Settings.group_concat_max_len};"
    self.connection.execute(set_group_concat_size_query)
  end

  def self.earliest_resolved_at
    with_scope do
      era = self.minimum(:resolved_at)
      (era < EpochDate::WWW_LAUNCH) ? EpochDate::WWW_LAUNCH : era
    end
  end

  def self.latest_resolved_at
    with_scope do
      self.maximum(:resolved_at)
    end
  end

  def self.stats_by_yearweek(metric,cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__,{metric: metric, scope_sql: current_scope ? current_scope.to_sql : ''})
      Rails.cache.fetch(cache_key,cache_options) do
        with_scope do
          _stats_by_yearweek(metric,cache_options)
        end
      end
    else
      with_scope do
        _stats_by_yearweek(metric,cache_options)
      end
    end
  end

  def self._stats_by_yearweek(metric,cache_options = {})
    stats = YearWeekStats.new
    # increase_group_concat_length
    with_scope do
      era = self.earliest_resolved_at
      if(era.blank?)
        return stats
      end
      lra = self.latest_resolved_at

      case metric
      when 'questions'
        metric_by_yearweek = self.group(YEARWEEK_SUBMITTED).count(:id)
      when 'experts'
        eligible_ids = self.pluck("#{self.table_name}.id")
        metric_by_yearweek = AaeResponse.where("question_id IN (#{eligible_ids.join(',')})").group(AaeResponse::YEARWEEK_RESOLVED).count('DISTINCT(responses.resolver_id)')
      when 'responsetime'
        questions_by_yearweek = self.group(YEARWEEK_SUBMITTED).count(:id)
        responsetime_by_yearweek = self.group(YEARWEEK_SUBMITTED).sum(:initial_response_time)
        metric_by_yearweek = {}
        responsetime_by_yearweek.each do |yearweek,total_response_time|
          metric_by_yearweek[yearweek] = ((questions_by_yearweek[yearweek].nil? or questions_by_yearweek[yearweek] == 0) ? 0 : total_response_time / questions_by_yearweek[yearweek].to_f / 3600.to_f)
        end
      else
        return stats
      end

      year_weeks = self.year_weeks_between_dates(era.to_date,lra.to_date)
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
