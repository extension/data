# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AaeController < ApplicationController

  def index
  end

  def demographics
    @demographic_questions = AaeDemographicQuestion.order(:questionorder).active
  end

  def evaluation
  end
  
end