# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class PagesController < ApplicationController
  
  def index
  end
  
  def show
    @page = Page.includes(:node).find(params[:id])
  end
  
  def group
    @group = Group.find(params[:id])
  end
  
  def list
    if(params[:group])
      @group = Group.find(params[:group])
    end
    if(@group)
      @scope = @group.pages
    else
      @scope = Page
    end
    
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      @datatype = nil
    else
      @scope = @scope.by_datatype(@datatype)
    end
    @pagelist = @scope.last_week_view_ordered.page(params[:page])
    
  end
  
  
  def graphs
    if(params[:group])
      @group = Group.find(params[:group])
    end
    
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      # for now, error later
      @datatype = 'Article'
    end
    
    if(@group)
      @graph_data = @group.graph_data_by_datatype(@datatype)
      (@percentiles_labels,@percentiles_data) = @group.traffic_stats_data_by_datatype_with_percentiles(@datatype)
    else
      @graph_data = Page.graph_data_by_datatype(@datatype)
      (@percentiles_labels,@percentiles_data) = Page.traffic_stats_data_by_datatype_with_percentiles(@datatype)
    end
  end

  def panda_impact_summary
    if(!params[:weeks].nil?)
      @panda_comparison_weeks =  params[:weeks].to_i
    else
      @panda_comparison_weeks = 3
    end
    @diffs = TotalDiff.panda_impacts(@panda_comparison_weeks)
  end
  
  def groups
  end

end