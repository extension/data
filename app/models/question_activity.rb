# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class QuestionActivity < ActiveRecord::Base
  belongs_to :question
  belongs_to :contributor

## constants
  ASSIGNED_TO = 1
  RESOLVED = 2
  REACTIVATE = 5
  REJECTED = 6
  NO_ANSWER = 7
  TAG_CHANGE = 8
  WORKING_ON = 9
  EDIT_QUESTION = 10
  PUBLIC_RESPONSE = 11
  REOPEN = 12
  CLOSED = 13
  INTERNAL_COMMENT = 14
  ASSIGNED_TO_GROUP = 15
  CHANGED_GROUP = 16
  CHANGED_LOCATION = 17

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    insert_values = []
    AaeQuestionEvent.includes(:initiator).find_in_batches(:batch_size => 100) do |question_event_group|
      insert_values = []
      question_event_group.each do |qe|
        insert_list = []
        contributor = qe.initiator
        next if(contributor.nil? or contributor.id == 1 or !contributor.has_exid?)
        insert_list << qe.id
        insert_list << contributor.darmok_id
        insert_list << qe.question_id
        insert_list << qe.event_state
        insert_list << (AaeQuestionEvent::EVENT_TO_TEXT_MAPPING[qe.event_state].nil? ? 'NULL' : ActiveRecord::Base.quote_value(AaeQuestionEvent::EVENT_TO_TEXT_MAPPING[qe.event_state]))       
        insert_list << ActiveRecord::Base.quote_value(qe.created_at.utc.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end # question_group
      columns = self.column_names
      insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end # all questions
  end

end
