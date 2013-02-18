# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DarmokTagging < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :darmok
  self.table_name= 'taggings'

  # tagging_kinds
  GENERIC = 0  # table defaults
  USER = 1
  SHARED = 2
  CONTENT = 3
  CONTENT_PRIMARY = 4  # for public communities, indicates the primary content tag for the community, if more than one

  belongs_to :darmok_community, :foreign_key => "taggable_id", :conditions => "taggable_type = 'Community' AND tagging_kind = #{CONTENT}"

  scope :page_content, where("taggable_type = 'Page'").where("tagging_kind = #{CONTENT}")


end
