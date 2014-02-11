# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class PageTagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :page


  def self.rebuild
    self.connection.execute('truncate table page_taggings;')
    DarmokTagging.page_content.find_in_batches do |group|
      insert_values = []
      group.each do |tagging|
        insert_list = []
        insert_list << tagging.taggable_id
        insert_list << tagging.tag_id
        insert_list << ActiveRecord::Base.quote_value(tagging.created_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(tagging.updated_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (page_id,tag_id,created_at,updated_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
    true
  end

end
