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
  
  scope :articles, where(:node_type => 'article')
  scope :faqs,     where(:node_type => 'faq')
  
  
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
  
  
  def self.published_since(date)
    where("nodes.created_at >= ?",date).joins(:workflow_events).where("workflow_events.event = #{WorkflowEvent::PUBLISHED}").select("distinct(nodes.id)")
  end
  
  def self.published_workflow_stats_since_migration
    published_workflow_stats_since_date(EpochDate::CREATE_FINAL_WIKI_MIGRATION)
  end
  
  def self.published_workflow_stats_since_date(date)
    articlelist = self.articles.published_since(date)
    article_workflow_count = {}
    articlelist.each do |a|
      article_workflow_count[a.id] = a.workflow_events.reviewed.count
    end
    article_has_workflow = article_workflow_count.select{|k,v| v > 0 }
    
    faqlist = self.faqs.published_since(date)
    faq_workflow_count = {}
    faqlist.each do |f|
      faq_workflow_count[f.id] = f.workflow_events.reviewed.count
    end
    faq_has_workflow = faq_workflow_count.select{|k,v| v > 0 }
    
    {:articles => [articlelist.size, article_has_workflow.size], :faqs => [faqlist.size, faq_has_workflow.size]}
  end    

end