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
  
  def groupdatatype
    @group = Group.find(params[:id])
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      # ToDo: error out
      @datatype = 'Article'
    end
    
    @graph_data = @group.graph_data_by_datatype(@datatype)
    (@percentiles_labels,@percentiles_data) = @group.traffic_stats_data_by_datatype_with_percentiles(@datatype)  
  end
  
  
  def datatype
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      # ToDo: error out
      @datatype = 'Article'
    end
    @graph_data = Page.graph_data_by_datatype(@datatype)
    (@percentiles_labels,@percentiles_data) = Page.traffic_stats_data_by_datatype_with_percentiles(@datatype)
  end
    
  
  def list
    @scope = Page
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      @datatype = nil
    else
      @scope = @scope.by_datatype(@datatype)
    end
    @pagelist = @scope.filtered_pagelist(params).page(params[:page])
    
    list_type = @datatype.nil? ? 'Pages' : @datatype.pluralize
    case(params[:filter])
    when 'viewed'
      @page_title = "Viewed #{list_type}"
      @page_title_display = "Viewed #{list_type}"
      @endpoint = 'viewed'
    when 'unviewed'
      @page_title = "Unviewed #{list_type}"
      @page_title_display = "Unviewed #{list_type}"
      @endpoint = 'unviewed'
    else
      @page_title = "All #{list_type}"
      @page_title_display = "All #{list_type}"
      @endpoint = 'all'
    end      

  end
  
  def grouplist
    @group = Group.find(params[:id])
    @scope = @group.pages
    
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      @datatype = nil
    else
      @scope = @scope.by_datatype(@datatype)
    end
    @pagelist = @scope.filtered_pagelist(params).page(params[:page])
    
        
    list_type = @datatype.nil? ? 'Pages' : @datatype.pluralize
    case(params[:filter])
    when 'viewed'
      @page_title = "Viewed #{list_type} for Group ##{@group.id}"
      @page_title_display = "Viewed #{list_type} for #{@group.name}"
      @endpoint = 'viewed'
    when 'unviewed'
      @page_title = "Unviewed #{list_type} for Group ##{@group.id}"
      @page_title_display = "Unviewed #{list_type} for #{@group.name}"
      @endpoint = 'unviewed'
    else
      @page_title = "All #{list_type}"
      @page_title_display = "All #{list_type}"
      @endpoint = 'all'
    end    
      
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
  
  
  def setdate
    if(params[:date])
      begin
        @date = Date.parse(params[:date])
        session[:date] = @date.to_s
      rescue
        # nothing
      end
    end

    if(!params[:currenturi].nil?)
      return redirect_to(Base64.decode64(params[:currenturi]))
    else
      return redirect_to(root_url)
    end
  end
  

end