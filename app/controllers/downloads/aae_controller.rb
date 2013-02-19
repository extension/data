# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Downloads::AaeController < ApplicationController
  before_filter :signin_required

  def index
  end

  def evaluation
  end

  def evaluation_download_csv
      send_data(AaeQuestion.evaluation_data_csv,
                :type => 'text/csv; charset=iso-8859-1; header=present',
                :disposition => "attachment; filename=evaluation_data_#{Date.today.to_s}.csv")
  end

  
end