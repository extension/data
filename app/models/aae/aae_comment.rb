# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AaeComment < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :aae
  self.table_name='comments'

  belongs_to :question, class_name: 'AaeQuestion'

end
