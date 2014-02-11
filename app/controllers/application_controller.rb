# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ApplicationController < ActionController::Base
  require_dependency 'year_week_stats'
  protect_from_forgery
  include AuthLib
  before_filter :check_for_rebuild, :signin_optional, :set_latest_yearweek, :check_for_metric

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

  def check_for_metric
    @metric = params[:metric]
    if(!PageStat.column_names.include?(@metric))
      @metric = 'unique_pageviews'
    end
    true
  end

end
