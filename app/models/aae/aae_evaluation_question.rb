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
  SCALE = 'scale'
  OPEN = 'open'
  OPEN_DOLLAR_VALUE = 'open_dollar_value'
  OPEN_TIME_VALUE = 'open_time_value'

## validations
## filters
## associations
  has_many :evaluation_answers, class_name: 'AaeEvaluationAnswer', foreign_key: 'evaluation_question_id'

## scopes
  scope :active, where(is_active: true)


  def answer_for_user_and_question(user,question)
    self.evaluation_answers.where(user_id: user.id).where(question_id: question.id).first
  end

  def answer_value_for_user_and_question(user,question)
    return nil if(question.nil? or user.nil?)
    if(answer = self.evaluation_answers.where(user_id: user.id).where(question_id: question.id).first)
      case self.responsetype
      when SCALE
        answer.value
      else
        answer.response
      end
    else
      nil
    end
  end

  def answer_counts_for_question(question)
    self.evaluation_answers.where(question_id: question.id).group(:response).count
  end


  def answer_total_for_question(question)
    self.evaluation_answers.where(question_id: question.id).count
  end

  def answer_counts
    self.evaluation_answers.group(:response).count
  end

  def answer_total
    self.evaluation_answers.count
  end

  def response_value(response)
    case self.responsetype
    when SCALE
      response.to_i
    when OPEN_DOLLAR_VALUE
      response.gsub(%r{[^\d\.]},'').to_i
    when OPEN_TIME_VALUE
      # interpret as days
      response.gsub(%r{[^\d]},'').to_i
    else 
      0
    end
  end

end
