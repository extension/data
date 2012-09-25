# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class HomeController < ApplicationController
  skip_before_filter :check_for_rebuild,  only: [:index]

  def index
    @hide_navbar = true
    @rebuild = Rebuild.latest
    if(@rebuild.in_progress?)
      return render :template => 'home/rebuild_in_progress'
    end
  end

end
