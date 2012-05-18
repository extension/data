# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Group < ActiveRecord::Base
  has_many :node_groups
  has_many :nodes, :through => :node_groups
  
  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};") 
    insert_values = []   
    DarmokCommunity.where("drupal_node_id IS NOT NULL").each do |group|
      insert_list = []
      insert_list << group.id
      insert_list << group.drupal_node_id
      insert_list << ActiveRecord::Base.quote_value(group.name)
      insert_list << group.is_launched
      insert_list << ActiveRecord::Base.quote_value(group.created_at.to_s(:db))
      insert_list << ActiveRecord::Base.quote_value(group.updated_at.to_s(:db))
      insert_values << "(#{insert_list.join(',')})"
    end
    insert_sql = "INSERT INTO #{self.table_name} VALUES #{insert_values.join(',')};"
    self.connection.execute(insert_sql)
  end
  
end