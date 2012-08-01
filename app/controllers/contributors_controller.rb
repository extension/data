# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ContributorsController < ApplicationController
  
  def show
    @contributor = Contributor.find(params[:id])
  end
  
end