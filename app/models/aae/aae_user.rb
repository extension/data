# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AaeUser < ActiveRecord::Base
  # connects to the aae database
  self.establish_connection :aae
  self.table_name='users'

  has_many :demographics, class_name: 'AaeDemographic', foreign_key: 'user_id'
  def has_exid?
    return self.kind == 'User'
  end

end


