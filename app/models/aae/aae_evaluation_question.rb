# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AaeEvaluationQuestion < ActiveRecord::Base
  # connects to the aae database
  self.establish_connection :aae
  self.table_name='evaluation_questions'


## attributes
  serialize :responses

## constants
  # types, strings in case we ever want to inherit from this model
  MULTIPLE_CHOICE = 'multiple_choice'
  SCALE = 'scale'
  OPEN = 'open'
  OPEN_DOLLAR_VALUE = 'open_dollar_value'
  OPEN_TIME_VALUE = 'open_time_value'
  TEXT = 'text'


## validations
## filters
## associations
  has_many :evaluation_answers, class_name: 'AaeEvaluationAnswer', foreign_key: 'evaluation_question_id'

## scopes
  scope :active, where(is_active: true)


  
  def response_value(response)
    case self.responsetype
    when MULTIPLE_CHOICE
      self.responses.index(response)
    when SCALE
      response.to_i
    when OPEN_DOLLAR_VALUE
      response.gsub(%r{[^\d\.]},'').to_i
    when OPEN_TIME_VALUE
      # interpret as days
      response.gsub(%r{[^\d]},'').to_i
    else 
      ''
    end
  end

  def reporting_response_value(response)
    case self.responsetype
    when MULTIPLE_CHOICE
      self.response_value(response) + 1
    else 
      self.response_value(response)
    end
  end
end
