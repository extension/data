# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AaeResponse < ActiveRecord::Base
  # connects to the aae database
  self.establish_connection :aae
  self.table_name='responses'

  # reporting scopes
  YEARWEEK_RESOLVED = 'YEARWEEK(responses.created_at,3)'

  belongs_to :question, class_name: 'AaeQuestion'
  belongs_to :resolver, :class_name => "AaeUser", :foreign_key => "resolver_id"
  belongs_to :submitter, :class_name => "AaeUser", :foreign_key => "submitter_id"

  scope :latest, order('created_at DESC')
  scope :expert, where(is_expert: true)
  scope :expert_after_public, where(is_expert: true).where(previous_expert: false)
  scope :non_expert, where(is_expert: false)
end