# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AaeEvaluationQuestion < ActiveRecord::Base
  include CacheTools

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
      # use the mean of all the numbers we find
      all_numerics = response.scan(%r{[\d\.,]+}).map{|i| i.tr(',','').to_i}
      if(all_numerics.size >= 1)
        all_numerics.mean.to_i
      else
        nil
      end
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

  def response_data(cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__)
      Rails.cache.fetch(cache_key,cache_options) do
        _response_data
      end
    else
      _response_data
    end
  end

  def _response_data
    data = {}
    limit_to_pool = Question.public_only.evaluation_eligible.pluck(:id).uniq
    data[:eligible] = limit_to_pool.size
    case self.responsetype
    when MULTIPLE_CHOICE
      response_counts = self.evaluation_answers.where("evaluation_answers.question_id IN (#{limit_to_pool.join(',')})").group('LOWER(response)').count
      data[:responses] = response_counts.values.sum
      data[:labels] = self.responses.map{|r| r.truncate(25)}
      data[:counts] = []
      self.responses.each do |r|
        data[:counts] << ((response_counts[r.downcase].blank?) ? 0 : response_counts[r.downcase])
      end
    when SCALE
      response_counts = self.evaluation_answers.where("evaluation_answers.question_id IN (#{limit_to_pool.join(',')})").group('value').count
      data[:responses] = response_counts.values.sum
      data[:labels] = (self.range_start..self.range_end).to_a
      data[:counts] = []
      (self.range_start..self.range_end).to_a.each do |value|
        data[:counts] << ((response_counts[value].blank?) ? 0 : response_counts[value])
      end
    when OPEN_DOLLAR_VALUE
      values = self.evaluation_answers.pluck(:value).compact
      data[:responses] = values.size
      data[:labels] = ['$0-$249','$250-$499','$500-$999','$1,000 - $2,499','$2,500 - $4,999','$5,000 - $9,999','>= $10,000']
      value_bins = {}
      data[:labels].each do |l|
        value_bins[l] = 0
      end
      values.each do |value|
        case value
        when 0..249
          value_bins['$0-$249'] +=1
        when 250..499
          value_bins['$250-$499'] +=1
        when 500..999
          value_bins['$500-$999'] +=1
        when 1000..2499
          value_bins['$1,000 - $2,499'] +=1
        when 2500..4999
          value_bins['$2,500 - $4,999'] +=1
        when 5000..9999
          value_bins['$5,000 - $9,999'] +=1          
        else
          value_bins['>= $10,000'] +=1
        end
      end
      data[:counts] = []
      data[:labels].each do |l|
        data[:counts] << ((value_bins[l].blank?) ? 0 : value_bins[l])
      end
    else
      return nil
    end
    data
  end

end
