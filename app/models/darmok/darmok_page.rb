# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class DarmokPage < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :darmok
  self.table_name= 'pages'
  JOINER = ", "
  SPLITTER = Regexp.new(/\s*,\s*/)

  has_one :darmok_link_stat, :foreign_key => "page_id"

  def link_counts
    linkcounts = {:total => 0, :external => 0,:local => 0, :wanted => 0, :internal => 0, :broken => 0, :redirected => 0, :warning => 0}
    if(!self.darmok_link_stat.nil?)
      linkcounts.keys.each do |key|
        linkcounts[key] = self.darmok_link_stat.send(key)
      end
    end
    return linkcounts
  end

end
