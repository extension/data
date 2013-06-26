# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ContributorGroup < ActiveRecord::Base
  belongs_to :group
  belongs_to :contributor


  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    insert_values = []
    PeopleCommunityConnection.joined.each do |community_connection|
      insert_list = []
      insert_list << community_connection.community_id
      insert_list << community_connection.person_id
      insert_list << 'NOW()'
      insert_values << "(#{insert_list.join(',')})"
    end
    insert_sql = "INSERT INTO #{self.table_name} (group_id,contributor_id,created_at) VALUES #{insert_values.join(',')};"
    self.connection.execute(insert_sql)
  end
end