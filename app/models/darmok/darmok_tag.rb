# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DarmokTag < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :darmok
  self.table_name= 'tags'

  has_many :darmok_taggings, :foreign_key => "tag_id"
  has_many :darmok_communities, :through => :darmok_taggings, :source => :darmok_community, :uniq => true



  def self.community_resource_tags
    includes(:darmok_taggings).where("taggings.tagging_kind = #{DarmokTagging::CONTENT} and taggable_type = 'PublishingCommunity'").order(:name)
  end

end
