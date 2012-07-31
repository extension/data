# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DataQuestion
  
  def self.page_totals_for_new_content
    returndata = {}
    nodes = Node.created_and_published_since(EpochDate::CREATE_FINAL_WIKI_MIGRATION)
    workflow_count = {}
    nodes.each do |n|
      workflow_count[n.id] = n.node_activities.reviews.count
      page = n.page
      if(!page.blank?)
        page = n.page
        returndata[page.id] = {:has_workflow => (workflow_count[n.id] && workflow_count[n.id] > 0)}
        returndata[page.id][:datatype] = page.datatype
        page_total = page.page_total
        if(!page_total.blank?)
          aup_week = page_total.eligible_weeks > 0 ? (page_total.unique_pageviews / page_total.eligible_weeks).to_f : 0
          returndata[page.id][:aup_week] = aup_week
        else
          returndata[page.id][:aup_week] = 0
        end
      end        
    end
    return returndata
  end
  

end
