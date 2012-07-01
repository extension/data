# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class GroupsController < ApplicationController
  
  def pages
    @group = Group.find(params[:id])
  end

end