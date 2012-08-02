# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class NodeMetacontribution < ActiveRecord::Base
  belongs_to :node
  belongs_to :contributor

  PUBLISHABLE_NODES = ['article','faq','news']

  scope :all_nodes, where(1) # just a convenience scope for scoping node types and activity types
  scope :articles, joins(:node).where("nodes.node_type = 'article'")
  scope :faqs, joins(:node).where("nodes.node_type = 'faq'")
  scope :news, joins(:node).where("nodes.node_type = 'news'")
  scope :forums, joins(:node).where("nodes.node_type = 'forum'")
  scope :publishables, joins(:node).where("nodes.node_type IN (#{PUBLISHABLE_NODES.collect{|type| quote_value(type)}.join(', ')})")
  scope :nonpublishables, joins(:node).where("nodes.node_type NOT IN (#{PUBLISHABLE_NODES.collect{|type| quote_value(type)}.join(', ')})")
  
  # used as a sanitycheck list
  NODE_SCOPES = ['all_nodes','articles','faqs','news','publishables','nonpublishables','forums']

  
  def associate_with_contributor
    checkstring = self.author.downcase
    if(contributor = Contributor.where('idstring = ?',checkstring).first)
      self.update_attribute(:contributor_id, contributor.id)
    elsif(contributor = Contributor.where('email = ?',checkstring).first)
      self.update_attribute(:contributor_id, contributor.id)
    elsif(contributors = Contributor.where("CONCAT(first_name,' ',last_name) = ?",checkstring))
      if(contributors.size == 1)
        contributor = contributors.first
        self.update_attribute(:contributor_id, contributor.id)
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
    self.associate_all_with_contributors
  end
  
  def self.associate_all_with_contributors
    self.find_each do |nc|
      nc.associate_with_contributor
    end
  end

  def self.contributions_display(contributions)
    list = contributions.split(',')
    list.uniq.join(', ')
  end
  
end
