# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AaeUser < ActiveRecord::Base
  # connects to the aae database
  self.establish_connection :aae
  self.table_name='users'

  DEFAULT_NAME = '"No name provided"'


  has_many :demographics, class_name: 'AaeDemographic', foreign_key: 'user_id'
  belongs_to :location, class_name: 'AaeLocation'
  belongs_to :county, class_name: 'AaeCounty'

  def has_exid?
    return self.kind == 'User'
  end

  def name
    if (self.first_name.present? && self.last_name.present?)
      return self.first_name + " " + self.last_name
    elsif self.public_name.present?
      return self.public_name
    end
    return DEFAULT_NAME
  end  

  def self.demographics_data_csv(filename)
    with_scope do
      _demographics_data_csv(filename)
    end
  end

  def self.demographics_private_data_csv(filename)
    with_scope do
      _demographics_data_csv(filename,true)
    end
  end  

  private 

  def self._demographics_data_csv(filename,show_submitter = false)
    CSV.open(filename,'wb') do |csv|
      headers = []
      if(show_submitter)
        headers << 'submitter_id'
      end
      headers << 'submitter_is_extension'
      headers << 'demographics_count'
      demographic_columns = []
      AaeDemographicQuestion.order(:id).active.each do |adq|
        demographic_columns << "demographic_#{adq.id}"
      end
      headers += demographic_columns
      csv << headers

      # data
      # evaluation_answer_questions
      eligible_submitters = Question.where(demographic_eligible: true).pluck(:submitter_id).uniq
      response_submitters = AaeDemographic.pluck(:user_id).uniq
      eligible_response_submitters = eligible_submitters & response_submitters      
      self.where("id in (#{eligible_response_submitters.join(',')})").order("RAND()").each do |person|
        demographic_count = person.demographics.count
        next if (demographic_count == 0)
        row = []
        if(show_submitter)
          row << person.id
        end
        row << person.has_exid?
        row << demographic_count
        demographic_data = {}
        person.demographics.each do |demographic_answer|
          demographic_data["demographic_#{demographic_answer.demographic_question_id}"] = demographic_answer.response
        end

        demographic_columns.each do |column|
          row << demographic_data[column]
        end

        csv << row
      end 
    end
  end


end


