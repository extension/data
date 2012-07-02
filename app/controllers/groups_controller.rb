# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class GroupsController < ApplicationController
  
  def pages
    @group = Group.find(params[:id])
  end
  
  def pagesgraphs
    @group = Group.find(params[:id])
    
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      # for now, error later
      @datatype = 'Article'
    end
    @graph_data = @group.graph_data_by_datatype(@datatype)
    (@percentiles_labels,@percentiles_data) = @group.traffic_stats_data_by_datatype_with_percentiles(@datatype)
  end
  
  def pageslist
    @group = Group.find(params[:id])
    
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      @page_title = "All Pages for Group ##{@group.id}"
      @page_title_display = "All Pages for #{@group.name}"
      @pagelist = @group.pages.last_week_view_ordered.page(params[:page])
    else
      @page_title = "#{@datatype.pluralize} for Group ##{@group.id}"
      @page_title_display = "#{@datatype.pluralize} for #{@group.name}"
      @pagelist = @group.pages.by_datatype(@datatype).last_week_view_ordered.page(params[:page])
    end
  end
  

end