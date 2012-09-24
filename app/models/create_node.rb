# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class CreateNode < ActiveRecord::Base
  self.establish_connection :create
  self.set_table_name 'node'
	self.primary_key = 'nid'
  self.inheritance_column = "inheritance_type"
  bad_attribute_names :changed

  def created_at
    Time.at(self.created).to_datetime
  end

  def updated_at
    Time.at(self.read_attribute('changed')).to_datetime
  end
end

