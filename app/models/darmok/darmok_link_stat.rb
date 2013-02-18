# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DarmokLinkStat < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :darmok
  self.table_name= 'link_stats'

  belongs_to :darmok_page, :foreign_key => "page_id"
end
