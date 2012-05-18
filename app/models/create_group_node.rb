# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class CreateGroupNode < ActiveRecord::Base
  self.establish_connection :create
  self.set_table_name 'field_data_group_audience'
  
  def created_at
    Time.at(self.group_audience_created).to_datetime
  end
  
end
