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

  DEFAULT_NAME = '"No name provided"'


  has_many :demographics, class_name: 'AaeDemographic', foreign_key: 'user_id'
  belongs_to :location, class_name: 'AaeLocation'
  belongs_to :county, class_name: 'AaeCounty'

  def has_exid?
    return self.kind == 'User'
  end

  def name
    if (self.first_name.present? && self.last_name.present?)
      return self.first_name + " " + self.last_name
    elsif self.public_name.present?
      return self.public_name
    end
    return DEFAULT_NAME
  end  

end


