# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class NodeGroup < ActiveRecord::Base
  belongs_to :node
	belongs_to :group


  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    insert_values = []
    group_mappings = {}
    Group.all.map{|g| group_mappings[g.create_gid] = g.id}
    CreateGroupNode.where(:entity_type => 'node').all.each do |groupnode|
      if(group_mappings[groupnode.group_audience_gid.to_i])
        insert_list = []
        insert_list << groupnode.entity_id
        insert_list << group_mappings[groupnode.group_audience_gid.to_i]
        insert_list << ActiveRecord::Base.quote_value(groupnode.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
    end
    insert_sql = "INSERT INTO #{self.table_name} (node_id,group_id,created_at) VALUES #{insert_values.join(',')};"
    self.connection.execute(insert_sql)
    true
  end

end
