# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DarmokAccount < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :darmok
  self.set_table_name 'accounts'
  self.inheritance_column = "inheritance_type"
  
end
