# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Person < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :people
  self.table_name= 'people'
end