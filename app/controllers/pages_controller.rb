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
      @endpoint = "Viewed #{@datatype.pluralize}"
    when 'unviewed'
      @page_title = "Unviewed #{list_type}"
      @page_title_display = "Unviewed #{list_type}"
      @endpoint = "Unviewed #{@datatype.pluralize}"
    else
      @page_title = "All #{list_type}"
      @page_title_display = "All #{list_type}"
      @endpoint = "All #{@datatype.pluralize}"
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
  
  
  def search
    if(params[:q])      
      if(params[:q].to_i > 0)
        @id_number = params[:q].to_i
        @page = Page.find_by_id(@id_number)
        @node = Node.find_by_id(@id_number)
        if(@page and !@node)
          return redirect_to(page_path(@page))
        elsif(@node and !@page and !@node.page.nil?)
          return redirect_to(page_path(@node.page))
        end
      else
        like= "%".concat(params[:q].concat("%"))
        @pagelist = Page.where("title like ?", like)
      end
    end
  end

end