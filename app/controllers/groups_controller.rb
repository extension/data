# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
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

  def node_activity
    @group = Group.find(params[:id])

    @node_scope = params[:node_scope]
    if(!Node::NODE_SCOPES.include?(@node_scope))
      @node_scope = 'all_nodes'
    end

    @activity = params[:activity]
    if(!NodeActivity::ACTIVITIES.include?(@activity))
      # for now, error later
      @activity =  NodeActivity::ALL_ACTIVITY
    end

    activity_scope =  @group.node_activities.includes(:node,:contributor)
    if(@activity !=  NodeActivity::ALL_ACTIVITY)
      activity_scope = activity_scope.where(activity: @activity)
    end

    @node_activity = activity_scope.order('created_at DESC').page(params[:page])
  end

  def node_graphs
    @group = Group.find(params[:id])

    @node_scope = params[:node_scope]
    if(!Node::NODE_SCOPES.include?(@node_scope))
      @node_scope = 'all_nodes'
    end

    @activity = params[:activity]
    if(!NodeActivity::ACTIVITIES.include?(@activity))
      # for now, error later
      @activity =  NodeActivity::ALL_ACTIVITY
    end
  end


def nodes
  @group = Group.find(params[:id])

  @activity = params[:activity]
  if(!NodeActivity::ACTIVITIES.include?(@activity))
    # for now, error later
    @activity =  NodeActivity::ALL_ACTIVITY
  end

  # this is a crapton of stats
  @overall_everything_stats = @group.nodes.overall_stats(@activity)
  @lastweek_everything_stats = @group.nodes.latest_activity.overall_stats(@activity)
  @everything_stats_by_week = @group.nodes.stats_by_yearweek(@activity)

  @overall_publishable_stats = YearWeekStatsComparator.new
  @lastweek_publishable_stats = YearWeekStatsComparator.new
  @publishable_stats_by_week = YearWeekStatsComparator.new
  Node::PUBLISHED_NODE_SCOPES.each do |node_scope|
    @overall_publishable_stats[node_scope] = @group.nodes.send(node_scope).overall_stats(@activity)
    @lastweek_publishable_stats[node_scope] = @group.nodes.send(node_scope).latest_activity.overall_stats(@activity)
    @publishable_stats_by_week[node_scope] = @group.nodes.send(node_scope).stats_by_yearweek(@activity)
  end

  @overall_administrative_stats = YearWeekStatsComparator.new
  @lastweek_administrative_stats = YearWeekStatsComparator.new
  @administrative_stats_by_week = YearWeekStatsComparator.new
  Node::ADMINISTRATIVE_NODE_SCOPES.each do |node_scope|
    @overall_administrative_stats[node_scope] = @group.nodes.send(node_scope).overall_stats(@activity)
    @lastweek_administrative_stats[node_scope] = @group.nodes.send(node_scope).latest_activity.overall_stats(@activity)
    @administrative_stats_by_week[node_scope] = @group.nodes.send(node_scope).stats_by_yearweek(@activity)
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
