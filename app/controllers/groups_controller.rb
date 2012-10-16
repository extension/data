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
    return redirect_to(pages_group_path(@group))
  end

  def pages
    @group = Group.find(params[:id])
    @landing_stats = @group.landing_stats.stats_by_yearweek(@metric)
    @datatype_stats = {}
    @overall_stats = {}
    @comparators = {}
    Page::DATATYPES.each do |datatype|
      @datatype_stats[datatype] = @group.pages.by_datatype(datatype).stats_by_yearweek(@metric)
      @overall_stats[datatype] = Page.by_datatype(datatype).stats_by_yearweek(@metric)
      @comparators[datatype]= YearWeekStatsComparator.new
      @comparators[datatype]["Overall #{datatype.pluralize}"] = @overall_stats[datatype]
      @comparators[datatype]["#{datatype.pluralize}"] = @datatype_stats[datatype]
    end
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

  def pagetags
    @group = Group.find(params[:id])
    @tagslist = Tag.pagetags_for_group(@group).order(:name).uniq
    @tagcounts = Tag.pagetags_for_group(@group).group('tags.id').count('tags.id')

  end

end