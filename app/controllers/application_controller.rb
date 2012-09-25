# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ApplicationController < ActionController::Base
  protect_from_forgery
  include AuthLib
  before_filter :check_for_rebuild, :signin_optional, :set_latest_yearweek

  def set_latest_yearweek
    @latest_yearweek = Analytic.latest_yearweek
  end

  def check_for_rebuild
    if(rebuild = Rebuild.latest)
      if(rebuild.in_progress?)
        # probably should return 307 instead of 302
        return redirect_to(root_path)
      end
    end
    true
  end

end
