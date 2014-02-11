# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AaeDemographicQuestion < ActiveRecord::Base
  include CacheTools

  # connects to the aae database
  self.establish_connection :aae
  self.table_name='demographic_questions'

  serialize :responses
  has_many :demographics, class_name: 'AaeDemographic', foreign_key: 'demographic_question_id'


  scope :active, where(is_active: true)

  def self.mean_response_rate
    response_rate = {}
    limit_pool = Question.public_only.demographic_eligible.pluck(:submitter_id).uniq
    response_rate[:eligible] = limit_pool.size
    limit_list = self.active.pluck(:id)
    response_rate[:responses] = (AaeDemographic.where("user_id in (#{limit_pool.join(',')})").where("demographic_question_id IN (#{limit_list.join(',')})").count / limit_list.size)
    response_rate
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
    limit_to_pool = Question.public_only.demographic_eligible.pluck(:submitter_id).uniq
    data[:eligible] = limit_to_pool.size
    response_counts = self.demographics.where("demographics.user_id IN (#{limit_to_pool.join(',')})").group('LOWER(response)').count
    data[:responses] = response_counts.values.sum
    data[:labels] = self.responses
    data[:counts] = []
    self.responses.each do |r|
      data[:counts] << ((response_counts[r.downcase].blank?) ? 0 : response_counts[r.downcase])
    end
    data
  end



end
