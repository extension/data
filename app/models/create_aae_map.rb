# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class CreateAaeMap < ActiveRecord::Base
  self.establish_connection :create
  self.set_table_name 'field_data_field_from_aaeid'
end
