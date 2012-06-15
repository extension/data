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
  scope :news,     where(:node_type => 'news')
  
  scope :has_page, where(:has_page => true)
  scope :created_since, lambda {|date| where("#{self.table_name}.created_at >= ?",date)}
    
  
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
    
    # set page flag
    update_sql = "UPDATE #{self.table_name},#{Page.table_name} SET #{self.table_name}.has_page = 1 WHERE #{self.table_name}.id = #{Page.table_name}.node_id and #{Page.table_name}.source = 'create'"
    self.connection.execute(update_sql)
    
  end
  
  def self.published_since(date)
    joins(:workflow_events).where("workflow_events.event = #{WorkflowEvent::PUBLISHED}").where("workflow_events.created_at > ?",date).select("distinct(#{self.table_name}.id),#{self.table_name}.*")
  end
  
  
  def self.published_workflow_stats_since_migration
    published_workflow_stats_since_date(EpochDate::CREATE_FINAL_WIKI_MIGRATION)
  end
  
  # def self.published_workflow_stats_since_date(date)
  #   articlelist = self.articles.created_and_published_since(date)
  #   article_workflow_count = {}
  #   articlelist.each do |a|
  #     article_workflow_count[a.id] = a.workflow_events.reviewed.count
  #   end
  #   article_has_workflow = article_workflow_count.select{|k,v| v > 0 }
  #   
  #   faqlist = self.faqs.created_and_published_since(date)
  #   faq_workflow_count = {}
  #   faqlist.each do |f|
  #     faq_workflow_count[f.id] = f.workflow_events.reviewed.count
  #   end
  #   faq_has_workflow = faq_workflow_count.select{|k,v| v > 0 }
  #   
  #   {:articles => [articlelist.size, article_has_workflow.size], :faqs => [faqlist.size, faq_has_workflow.size]}
  # end    
  
  
  def self.published_workflow_stats_since_date(date,rawnodecounts=false)
    nodelist = []
    with_scope do
      nodelist = self.published_since(date)
    end
    nodecounts = {}
    nodelist.each do |node|
      published_count = 0
      reviewed_counts = []
      reviews = 0
      node.workflow_events.created_since(date).each do |wfe|
        if(wfe.event == WorkflowEvent::PUBLISHED)
          published_count += 1
          reviewed_counts << reviews
          reviews = 0
        elsif(wfe.is_reviewed_event?)
          reviews += 1
        end
      end
      nodecounts[node.id] = {:published => published_count, :reviewed => reviewed_counts.select{|i| i> 0}.size}
    end
    if(rawnodecounts)
      nodecounts
    else
      stats = {:total => 0, :reviewed => 0, :publish_count => 0, :review_count => 0}
      nodecounts.each do |node_id,counts|
        stats[:total] += 1
        stats[:reviewed] += 1 if counts[:reviewed] > 0
        stats[:publish_count] += counts[:published]
        stats[:review_count] += counts[:reviewed]
      end
      stats
    end
  end
  


end