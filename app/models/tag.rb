# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Tag < ActiveRecord::Base
  has_many :analytics
  has_many :page_taggings
  has_many :pages, :through => :page_taggings
  has_many :analytics, :through => :pages
  has_many :page_stats, :through => :pages
  has_many :week_diffs, :through => :pages
  has_many :week_totals
  has_many :published_nodes, :source => :node, :through => :pages
  belongs_to :group

  scope :grouptags, where("group_id > 0")


  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    DarmokTag.find_in_batches do |group|
      insert_values = []
      group.each do |tag|
        insert_list = []
        insert_list << tag.id
        insert_list << ActiveRecord::Base.quote_value(tag.name)
        insert_list << ActiveRecord::Base.quote_value(tag.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (id,name,created_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end

    # set groups
    DarmokTag.community_resource_tags.each do |community_tag|
      group_id = community_tag.darmok_communities.first.id
      update_sql = "UPDATE #{self.table_name} SET group_id = #{group_id} WHERE #{self.table_name}.id = #{community_tag.id}"
      self.connection.execute(update_sql)
    end
  end
  true
end
