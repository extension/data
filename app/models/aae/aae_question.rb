# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AaeQuestion < ActiveRecord::Base
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
  SUBMITTED_TEXT = 'submitted'
  RESOLVED_TEXT = 'resolved'
  ANSWERED_TEXT = 'answered'
  NO_ANSWER_TEXT = 'not_answered'
  REJECTED_TEXT = 'rejected'
  CLOSED_TEXT = 'closed'

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
  
  has_many :responses, class_name: 'AaeResponse', foreign_key: 'question_id'
  has_many :evaluation_answers, class_name: 'AaeEvaluationAnswer', foreign_key: 'question_id' 
## scopes
  scope :answered, where(:status_state => STATUS_RESOLVED)
  scope :submitted, where(:status_state => STATUS_SUBMITTED)
  scope :not_rejected, conditions: "status_state <> #{STATUS_REJECTED}"
  scope :since_changeover, where("DATE(#{self.table_name}.created_at) >= '2012-12-04'")


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

  def location_from_ip
    AaeLocation.find_by_geoip(self.user_ip)
  end


  def initial_response_time
    if(response = self.responses.order('created_at ASC').first)
      response.created_at - self.created_at
    else
      nil
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



  def self.evaluation_data
    return_data = []
    submitter_id_map = {}
    with_scope do
      self.where(evaluation_sent: true).each do |question|
        question_data = {}

        # question metadata
        question_data[:response_time] = question.initial_response_time / (60*60*24)

        if(location = question.location)
          question_data[:location] = location.name
        end

        if(county = question.county)
          question_data[:county] = county.name
        end

        if(group = question.assigned_group)
          question_data[:group] = group.name
        end

        # submitter metadata
        if(submitter = question.submitter)
          submitter_id_map[submitter.id] ||= 1
          question_data[:submitter] = submitter.id
          question_data[:has_exid] = submitter.has_exid?
          question_data[:demographics_count] = submitter.demographics.count
          if(question_data[:demographics_count] >= 1)
            submitter.demographics.each do |demographic|
              question_data["demographic #{demographic.demographic_question_id}"] = demographic.response
            end
          end
        end

        # evaluation
        question_data[:evaluation_count] = question.evaluation_answers.count
        if(question_data[:evaluation_count] >= 1)
          question.evaluation_answers.each do |ea|
            question_data["evaluation #{ea.evaluation_question_id}"] = ea.response
          end
        end
        return_data << question_data
      end # questions
    end #scope

    # anonymize submitters
    submitter_pool_size = submitter_id_map.keys.length
    random_id_array = (1..submitter_pool_size).to_a.sample(submitter_pool_size)
    submitter_id_map.each_with_index do |(submitter_id,value),index| 
      submitter_id_map[submitter_id] = random_id_array[index]
    end

    return_data.each do |question_data|
      if(submitter_id = question_data[:submitter])
        question_data[:submitter] = submitter_id_map[submitter_id]
      end
    end

    return_data.shuffle
  end

end
