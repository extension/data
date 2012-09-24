# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Revision < ActiveRecord::Base
  belongs_to :node

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    CreateRevision.find_in_batches do |group|
      insert_values = []
      group.each do |revision|
        insert_list = []
        insert_list << revision.vid
        insert_list << revision.nid
        insert_list << revision.uid
        insert_list << ActiveRecord::Base.quote_value(revision.log)
        insert_list << ActiveRecord::Base.quote_value(revision.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (id,node_id,contributor_id,log,created_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
  end

end
