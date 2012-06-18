# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class UpdateTime < ActiveRecord::Base
  serialize :additionaldata
  attr_accessible :item,:run_time,:additionaldata,:operation
    
  def self.log(item,operation,run_time,additionaldata=nil)
    self.create(:item => item, :operation => operation, :run_time => run_time, :additionaldata => additionaldata)
  end
    
end
