# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class WorkflowEvent < ActiveRecord::Base
  belongs_to :node
  
  DRAFT = 1
  READY_FOR_REVIEW = 2
  REVIEWED = 3
  READY_FOR_PUBLISH = 4
  PUBLISHED = 5
  UNPUBLISHED = 6
  INACTIVATED = 7
  ACTIVATED = 8
  READY_FOR_COPYEDIT = 9
  
  scope :reviewed, where("event IN (#{READY_FOR_REVIEW},#{REVIEWED},#{READY_FOR_PUBLISH},#{READY_FOR_COPYEDIT})")
  scope :created_since, lambda {|date| where("#{self.table_name}.created_at >= ?",date)}
  
  
  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")    
    CreateWorkflowEvent.find_in_batches do |group|
      insert_values = []
      group.each do |cwe|
        insert_list = []
        insert_list << cwe.weid
        insert_list << cwe.node_id
        insert_list << cwe.node_workflow_id
        insert_list << cwe.user_id
        insert_list << cwe.revision_id
        insert_list << cwe.event_id
        insert_list << ActiveRecord::Base.quote_value(cwe.description)
        insert_list << ActiveRecord::Base.quote_value(cwe.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
  end
  
  def is_reviewed_event?
    [READY_FOR_REVIEW,REVIEWED,READY_FOR_PUBLISH,READY_FOR_COPYEDIT].include?(self.event)
  end
	
end	
