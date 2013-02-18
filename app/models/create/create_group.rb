# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class CreateGroup < ActiveRecord::Base
  self.establish_connection :create
  self.table_name='og'
	self.primary_key = 'gid'

  def created_at
    Time.at(self.created).to_datetime
  end
end
