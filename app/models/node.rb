# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Node < ActiveRecord::Base
  has_one :page
  has_many :node_groups
  has_many :nodes, :through => :node_groups
  has_many :workflow_events
  has_many :aae_nodes
  
  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")    
    CreateNode.find_in_batches do |group|
      insert_values = []
      group.each do |node|
        insert_list = []
        insert_list << node.nid
        insert_list << node.vid
        insert_list << ActiveRecord::Base.quote_value(node.type)
        insert_list << ActiveRecord::Base.quote_value(node.title)
        insert_list << ActiveRecord::Base.quote_value(node.created_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(node.updated_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (id,revision_id,node_type,title,created_at,updated_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
  end
  
end