# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file
require 'csv'

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
  STATUS_TEXT = {
    STATUS_SUBMITTED => 'submitted',
    STATUS_RESOLVED => 'answered',
    STATUS_NO_ANSWER => 'not_answered',
    STATUS_REJECTED => 'rejected',
    STATUS_CLOSED => 'closed'
  }

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
  has_many :comments, class_name: 'AaeComment', foreign_key: 'question_id' 

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

  def initial_response_time
    if(response = self.responses.order('created_at ASC').first)
      response.created_at - self.created_at
    else
      nil
    end
  end

  def tags
    AaeTag.includes(:taggings).where('taggings.taggable_type = ?','Question').where('taggings.taggable_id = ?', self.id)
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
        question_data['response_time'] = (question.initial_response_time / (60)).floor

        if(location = question.location)
          question_data['location'] = location.name
        end

        if(county = question.county)
          question_data['county'] = county.name
        end

        if(group = question.assigned_group)
          question_data['group'] = group.name
        end

        # submitter metadata
        if(submitter = question.submitter)
          submitter_id_map[submitter.id] ||= 1
          question_data['submitter'] = submitter.id
          question_data['has_extension_account'] = submitter.has_exid?
          question_data['demographics_count'] = submitter.demographics.count
          if(question_data['demographics_count'] >= 1)
            submitter.demographics.each do |demographic|
              question_data["demographic_#{demographic.demographic_question_id}"] = demographic.response
            end
          end
        end

        # evaluation
        question_data['evaluation_count'] = question.evaluation_answers.count
        if(question_data['evaluation_count'] >= 1)
          question.evaluation_answers.each do |ea|
            question_data["evaluation_#{ea.evaluation_question_id}"] = ea.response
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
      if(submitter_id = question_data['submitter'])
        question_data['submitter'] = submitter_id_map[submitter_id]
      end
    end

    return_data.shuffle
  end

  def self.evaluation_data_csv   
    with_scope do 
      evaldata = self.evaluation_data
      columns = ['response_time','location','county','group','submitter','has_extension_account']
      columns << 'demographics_count'
      AaeDemographicQuestion.order(:id).active.each do |adq|
        columns << "demographic_#{adq.id}"
      end
      columns << 'evaluation_count'
      AaeEvaluationQuestion.order(:id).active.each do |aeq|
        columns << "evaluation_#{aeq.id}"
      end    
      CSV.generate do |csv|
        headers = []
        columns.each do |column|
          headers << column
        end
        csv << headers
        evaldata.each do |question_data|
          row = []
          columns.each do |column|
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
  end

  def self.questions_csv(filename)
    with_scope do
      question_columns = [
        'question_id',
        'detected_location',
        'detected_county',
        'location',
        'county',
        'original_group',
        'assigned_group',
        'status',
        'submitted_from_mobile',
        'submitted_at',
        'comment_count',
        'public_responders',
        'expert_responders',
        'expert_response_count',
        'public_response_count',
        'initial_response_time',
        'tags'
      ]
      CSV.open(filename,'wb') do |csv|
        headers = []
        question_columns.each do |column|
          headers << column
        end
        csv << headers
        self.not_rejected.find_in_batches do |question_group|
          question_group.each do |question|
            row = []
            row << question.id
            [ 'detected_location','detected_county','location','county','original_group','assigned_group' ].each do |qattr|
              row << self.name_or_nil(question.send(qattr))
            end
            row <<  STATUS_TEXT[question.status_state]
            row << question.is_mobile?
            row << question.created_at.utc.strftime("%Y-%m-%d %H:%M:%S")
            row << question.comments.count
            row << question.responses.public.count('distinct(submitter_id)')
            row << question.responses.expert.count('distinct(resolver_id)')
            row << question.responses.public.count
            row << question.responses.expert.count
            row << question.initial_response_time
            row << question.tags.map(&:name).join(',')
            # tags
            csv << row
          end # question
        end # question group
      end # csv 
    end # with_scope

  end 

  def self.name_or_nil(item)
    item.nil? ? nil : item.name
  end



end
