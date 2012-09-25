# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AaeNode < ActiveRecord::Base
  belongs_to :node

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    insert_values = []
    CreateAaeMap.all.each do |aae_map|
      insert_list = []
      insert_list << aae_map.entity_id
      insert_list << aae_map.field_from_aaeid_value
      insert_values << "(#{insert_list.join(',')})"
    end
    insert_sql = "INSERT INTO #{self.table_name} (node_id,aae_id) VALUES #{insert_values.join(',')};"
    self.connection.execute(insert_sql)
    true
  end

end
