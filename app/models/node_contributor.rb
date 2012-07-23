# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class NodeContributor < ActiveRecord::Base
  belongs_to :node
  belongs_to :user
  
  def associate_with_user
    checkstring = self.author.downcase
    if(contributor = User.where('idstring = ?',checkstring).first)
      self.update_attribute(:user_id, contributor.id)
    elsif(contributor = User.where('email = ?',checkstring).first)
      self.update_attribute(:user_id, contributor.id)
    elsif(contributors = User.where("CONCAT(first_name,' ',last_name) = ?",checkstring))
      if(contributors.size == 1)
        contributor = contributors.first
        self.update_attribute(:user_id, contributor.id)
      end
    end    
  end

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")    
    insert_values = []
    CreateContributor.where('entity_type = ?','node').where('deleted = 0').each do |contribution|
      next if contribution.field_contributors_contribution_author.nil?
      insert_list = []
      insert_list << contribution.entity_id
      insert_list << contribution.revision_id
      insert_list << ActiveRecord::Base.quote_value(contribution.field_contributors_contribution_role)
      insert_list << ActiveRecord::Base.quote_value(contribution.field_contributors_contribution_author)
      insert_list << ActiveRecord::Base.quote_value(contribution.contributed_at.to_s(:db))
      insert_list << 'NOW()'
      insert_values << "(#{insert_list.join(',')})"
    end
    insert_sql = "INSERT INTO #{self.table_name} (node_id,node_revision_id,role,author,contributed_at,created_at) VALUES #{insert_values.join(',')};"
    self.connection.execute(insert_sql)
    
    # associate
    self.associate_all_with_users
  end
  
  def self.associate_all_with_users
    self.find_each do |nc|
      nc.associate_with_user
    end
  end
  
end
