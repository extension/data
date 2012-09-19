# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class GroupsController < ApplicationController

  def index
    @grouplist = Group.launched.order(:name)
  end

	def show
    @group = Group.find(params[:id])
    @index_stats = @group.landing_stats.stats_by_yearweek('unique_pageviews')
    @latest_yearweek = Analytic.latest_yearweek
  end


  def pagelist
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
      @endpoint = "Viewed #{@datatype.pluralize}"
    when 'unviewed'
      @page_title = "Unviewed #{list_type} for Group ##{@group.id}"
      @page_title_display = "Unviewed #{list_type} for #{@group.name}"
      @endpoint = "Unviewed #{@datatype.pluralize}"
    else
      @page_title = "All #{list_type}"
      @page_title_display = "All #{list_type}"
      @endpoint = "All #{@datatype.pluralize}"
    end    
      
  end
end