# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class LearnVersion < ActiveRecord::Base
  # connects to the learn database
  self.establish_connection :learn
  self.table_name='versions'

  belongs_to :learner, class_name: 'LearnLearner', foreign_key: 'whodunnit'

end
