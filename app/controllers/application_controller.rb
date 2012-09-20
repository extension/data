# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ApplicationController < ActionController::Base
  protect_from_forgery
  include AuthLib
  before_filter :signin_optional, :set_latest_yearweek

  def set_latest_yearweek
    @latest_yearweek = Analytic.latest_yearweek
  end

end
