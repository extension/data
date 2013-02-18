# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class CreateWorkflowEvent < ActiveRecord::Base
  self.establish_connection :create
  self.table_name= 'node_workflow_events'
	self.primary_key = 'weid'


  def created_at
    Time.at(self.created).to_datetime
  end

end

