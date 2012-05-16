# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class PageTagging < ActiveRecord::Base
  belongs_to :resource_tag
  belongs_to :page


  def self.rebuild
    self.connection.execute('truncate table page_taggings;')
    tagging_database = self.connection.instance_variable_get("@config")[:database]      
    page_count = 0
    insert_values = []
    now = Time.now.utc.to_s(:db)
    resource_tags = {}
    ResourceTag.all.map{|tag| resource_tags[tag.name] = tag.id}
    Page.all.each do |page|
      page_count += 1
      if(!page.resource_tag_names.blank?)
        tagarray = page.resource_tag_names.split(',')
        tagarray.each do |tagname|
          if(resource_tags[tagname])
            resource_tag_id = resource_tags[tagname]
          else
            resource_tag_id = ResourceTag.find_or_create_by_name(tagname).id
          end
          insert_values << "(#{page.id},#{resource_tag_id},#{ActiveRecord::Base.quote_value(now)},#{ActiveRecord::Base.quote_value(now)})"
        end
      end
    end
    insert_sql = "INSERT INTO page_taggings (page_id,resource_tag_id,created_at,updated_at) VALUES #{insert_values.join(',')}"
    self.connection.execute(insert_sql)
  end
  
end
