# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class UpdateTime < ActiveRecord::Base
  serialize :additionaldata
  attr_accessible :rebuild_id, :item,:run_time,:additionaldata,:operation

  def self.log(rebuild,item,operation,run_time,additionaldata=nil)
    self.create(rebuild_id: rebuild.id, item: item, operation: operation, run_time: run_time, additionaldata: additionaldata)
  end

end
