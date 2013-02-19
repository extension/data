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

  ## attributes
  ## constants
  ## validations
  ## filters
  ## associations

  belongs_to :evaluation_question, class_name: 'AaeEvaluationQuestion'
  belongs_to :user, class_name: 'AaeUser'
  belongs_to :question, class_name: 'AaeQuestion'

  ## scopes


end
