# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class LinkStat < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :darmok
  belongs_to :darmok_page, :foreign_key => "page_id"
end
