# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class CreateContributor < ActiveRecord::Base
  self.establish_connection :create
  self.table_name= 'field_data_field_contributors'

  def contributed_at
    if(!self.field_contributors_contribution_date.nil?)
      Time.at(self.field_contributors_contribution_date).to_datetime
    end
  end

end
