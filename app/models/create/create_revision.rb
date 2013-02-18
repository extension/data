# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class CreateRevision < ActiveRecord::Base
  self.establish_connection :create
  self.table_name= 'node_revision'
	self.primary_key = 'vid'

  def created_at
    Time.at(self.timestamp).to_datetime
  end

end

