# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class DarmokPublishingCommunity < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :darmok
  self.table_name= 'publishing_communities'
end