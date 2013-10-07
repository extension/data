# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AaeReadabilityScore < ActiveRecord::Base
  include MarkupScrubber

  serialize :data
  serialize :frequencies

  attr_accessible :aae_response_id, :question_id, :is_expert, :flesch, :kincaid, :fog, :frequencies, :data 

  def self.create_or_update_from_response(aae_response)
    if(!score = self.find_by_aae_response_id(aae_response.id))
      score = self.new(aae_response_id: aae_response.id)
    end
    score.aae_response_at = aae_response.created_at
    score.question_id = aae_response.question_id
    score.is_expert = aae_response.is_expert
    if(report = self.readability(aae_response.body))
      score.flesch = report.flesch if !report.flesch.nan?
      score.kincaid = report.kincaid if !report.kincaid.nan?
      score.fog = report.fog if !report.fog.nan?
      # ignore for now
      #score.frequencies = report.frequencies
    end

    score.save
  end

  def self.readability(content)
    Lingua::EN::Readability.new(self.html_to_text(content).gsub(/[[:space:]]/, ' '))
  end

  def self.rebuild
    AaeResponse.find_in_batches do |group|
      group.each do |response|
        create_or_update_from_response(response)
      end
    end
  end    

end