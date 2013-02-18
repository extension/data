# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AaeEvaluationAnswer < ActiveRecord::Base
  # connects to the aae database
  self.establish_connection :aae
  self.table_name='evaluation_answers'
end
