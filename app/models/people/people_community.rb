# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class PeopleCommunity < ActiveRecord::Base
  self.establish_connection :people
  self.table_name= 'communities'
end