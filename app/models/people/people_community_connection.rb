# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class PeopleCommunityConnection < ActiveRecord::Base
  self.establish_connection :people
  self.table_name= 'community_connections'

  scope :joined, where("community_connections.connectiontype IN ('leader','member')")
end