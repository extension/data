# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class NodeEvent < ActiveRecord::Base
  belongs_to :node
  belongs_to :user
  
  
  DRAFT = 1
  READY_FOR_REVIEW = 2
  REVIEWED = 3
  READY_FOR_PUBLISH = 4
  PUBLISHED = 5
  UNPUBLISHED = 6
  INACTIVATED = 7
  ACTIVATED = 8
  READY_FOR_COPYEDIT = 9
  
  EDIT = 101
  COMMENT = 102
  
  
  EVENT_STRINGS = {
    DRAFT => 'moved to draft',
    READY_FOR_REVIEW => 'marked ready for review',
    REVIEWED => 'reviewed',
    READY_FOR_PUBLISH => 'marked ready for publishing',
    PUBLISHED => 'published',
    UNPUBLISHED => 'unpublished',
    INACTIVATED => 'marked inactive',
    ACTIVATED => 'marked as active',
    READY_FOR_COPYEDIT => 'marked ready for copy editing',
    EDIT => 'edited',
    COMMENT => 'added comment'
  }
  
  scope :reviewed, where("event IN (#{READY_FOR_REVIEW},#{REVIEWED},#{READY_FOR_PUBLISH},#{READY_FOR_COPYEDIT})")
  scope :created_since, lambda {|date| where("#{self.table_name}.created_at >= ?",date)}
  
  def event_to_s
    if(EVENT_STRINGS[self.event])
      EVENT_STRINGS[self.event]
    else
      'unknown'
    end
  end
  
  
  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")    
    
    # revisions
    CreateRevision.find_in_batches do |group|
      insert_values = []
      group.each do |revision|
        insert_list = []
        insert_list << revision.nid
        insert_list << revision.uid
        insert_list << revision.vid
        insert_list << EDIT
        insert_list << ActiveRecord::Base.quote_value(revision.log)
        insert_list << ActiveRecord::Base.quote_value(revision.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (node_id,user_id,node_revision_id,event,log,created_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
        
    # workflow events
    CreateWorkflowEvent.find_in_batches do |group|
      insert_values = []
      group.each do |cwe|
        insert_list = []
        insert_list << cwe.node_id
        insert_list << cwe.user_id
        insert_list << cwe.revision_id
        insert_list << cwe.event_id
        insert_list << ActiveRecord::Base.quote_value(cwe.description)
        insert_list << ActiveRecord::Base.quote_value(cwe.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (node_id,user_id,node_revision_id,event,log,created_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
    
    # comments
    CreateComment.find_in_batches do |group|
      insert_values = []
      group.each do |comment|
        insert_list = []
        insert_list << comment.nid
        insert_list << comment.uid
        insert_list << COMMENT
        insert_list << ActiveRecord::Base.quote_value(comment.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (node_id,user_id,event,created_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
      
  end
  
  def is_reviewed_event?
    [READY_FOR_REVIEW,REVIEWED,READY_FOR_PUBLISH,READY_FOR_COPYEDIT].include?(self.event)
  end

  
end	
