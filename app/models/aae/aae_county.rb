# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AaeCounty < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :aae
  self.table_name='counties'
end

