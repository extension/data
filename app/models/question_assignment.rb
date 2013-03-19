# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class QuestionAssignment < ActiveRecord::Base
  belongs_to :question
  belongs_to :contributor
  belongs_to :assigner, class_name: 'Contributor', foreign_key: 'assigned_by'
  belongs_to :handler, class_name: 'Contributor', foreign_key: 'next_handled_by' 

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    insert_values = []
    AaeQuestionEvent.individual_assignments.find_in_batches(:batch_size => 100) do |question_event_group|
      insert_values = []
      question_event_group.each do |qe|
        insert_list = []
        recipient = qe.recipient
        assigner = qe.initiator
        question = qe.question
        next_event = qe.next_handling_event
        next if(question.blank? or question.status_state == AaeQuestion::STATUS_REJECTED)
        insert_list << qe.id
        insert_list << (recipient.nil? ? 'NULL' : recipient.darmok_id)
        insert_list << question.id
        insert_list << (assigner.nil? ? 'NULL' : assigner.id)
        insert_list << ActiveRecord::Base.quote_value(qe.created_at.utc.to_s(:db))
        insert_list << (qe.created_at - question.created_at)
        if(!next_event.blank?)
          insert_list << (next_event.created_at - qe.created_at)
          case next_event.event_state
          when AaeQuestionEvent::ASSIGNED_TO   
            insert_list << ActiveRecord::Base.quote_value('reassignment')
          when AaeQuestionEvent::ASSIGNED_TO_GROUP
            insert_list << ActiveRecord::Base.quote_value('reassignment')
          when AaeQuestionEvent::RESOLVED
            insert_list << ActiveRecord::Base.quote_value('answered')
          when AaeQuestionEvent::NO_ANSWER
            insert_list << ActiveRecord::Base.quote_value('no_answer')
          when AaeQuestionEvent::CLOSED
            insert_list << ActiveRecord::Base.quote_value('closed')
          else
            insert_list << ActiveRecord::Base.quote_value('unknown')
          end
          insert_list << (next_event.initiator.nil? ? 'NULL' : next_event.initiator.darmok_id)
          insert_list << ActiveRecord::Base.quote_value(next_event.created_at.utc.to_s(:db))
          insert_list << next_event.id
          insert_list << ((next_event.initiator.nil? or recipient.blank?) ? 'NULL' : (next_event.initiator.darmok_id == recipient.darmok_id ))
        else
          insert_list << 'NULL' # time_assigned
          insert_list << 'NULL' # next_handled_result
          insert_list << 'NULL' # next_handled_by
          insert_list << 'NULL' # next_handled_at
          insert_list << 'NULL' # next_handled_id
          insert_list << 'NULL' # handled_by_assignee
        end
        insert_values << "(#{insert_list.join(',')})"
      end # question_group
      columns = self.column_names
      insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end # all questions
  end

end