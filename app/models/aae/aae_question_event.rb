# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AaeQuestionEvent < ActiveRecord::Base
  # connects to the aae database
  self.establish_connection :aae
  self.table_name='question_events'

## includes

## attributes
  serialize :updated_question_values


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

  EVENT_TO_TEXT_MAPPING = { ASSIGNED_TO => 'assigned to',
                            RESOLVED => 'resolved by',
                            REACTIVATE => 're-activated by',
                            REJECTED => 'rejected by',
                            NO_ANSWER => 'no answer given',
                            TAG_CHANGE => 'tags edited by',
                            WORKING_ON => 'worked on by',
                            EDIT_QUESTION => 'edited question',
                            PUBLIC_RESPONSE => 'public response',
                            REOPEN => 'reopened',
                            CLOSED => 'closed',
                            INTERNAL_COMMENT => 'commented',
                            ASSIGNED_TO_GROUP => 'assigned to group',
                            CHANGED_GROUP => 'group changed',
                            CHANGED_LOCATION => 'location changed' }
## validations

## filters

## associations
  belongs_to :question, class_name: 'AaeQuestion'
  belongs_to :initiator, :class_name => "AaeUser", :foreign_key => "initiated_by_id"
  belongs_to :submitter, :class_name => "AaeUser", :foreign_key => "submitter_id"
  belongs_to :recipient, :class_name => "AaeUser", :foreign_key => "recipient_id"
  belongs_to :assigned_group, :class_name => "AaeGroup", :foreign_key => "recipient_group_id"
  belongs_to :previous_recipient, :class_name => "AaeUser", :foreign_key => "previous_recipient_id"
  belongs_to :previous_initiator,  :class_name => "AaeUser", :foreign_key => "previous_initiator_id"
  belongs_to :previous_handling_recipient, :class_name => "AaeUser", :foreign_key => "previous_handling_recipient_id"
  belongs_to :previous_handling_initiator,  :class_name => "AaeUser", :foreign_key => "previous_handling_initiator_id"
  belongs_to :previous_group, class_name: 'AaeGroup'
  belongs_to :changed_group, class_name: 'AaeGroup'

## scopes
  scope :latest, {:order => "created_at desc", :limit => 1}
  scope :latest_handling, {:conditions => "event_state IN (#{ASSIGNED_TO},#{ASSIGNED_TO_GROUP},#{RESOLVED},#{REJECTED},#{NO_ANSWER})",:order => "created_at desc", :limit => 1}
  scope :handling_events, :conditions => "event_state IN (#{ASSIGNED_TO},#{ASSIGNED_TO_GROUP},#{RESOLVED},#{REJECTED},#{NO_ANSWER})"



end
