# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class CreateComment < ActiveRecord::Base
  self.establish_connection :create
  self.table_name= 'comment'
	self.primary_key = 'cid'

  def created_at
    Time.at(self.created).to_datetime
  end

end

