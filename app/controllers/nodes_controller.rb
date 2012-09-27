# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class NodesController < ApplicationController
  before_filter :check_for_group
  helper_method :display_node_scope

  def index
    @activity = params[:activity]
    if(!NodeActivity::ACTIVITIES.include?(@activity))
      # for now, error later
      @activity =  NodeActivity::ALL_ACTIVITY
    end

    # this is a crapton of stats
    @overall_everything_stats = Node.overall_stats(@activity)
    @lastweek_everything_stats = Node.latest_activity.overall_stats(@activity)
    @everything_stats_by_week = Node.stats_by_yearweek(@activity)

    @overall_publishable_stats = YearWeekStatsComparator.new
    @lastweek_publishable_stats = YearWeekStatsComparator.new
    @publishable_stats_by_week = YearWeekStatsComparator.new
    Node::PUBLISHED_NODE_SCOPES.each do |node_scope|
      @overall_publishable_stats[node_scope] = Node.send(node_scope).overall_stats(@activity)
      @lastweek_publishable_stats[node_scope] = Node.send(node_scope).latest_activity.overall_stats(@activity)
      @publishable_stats_by_week[node_scope] = Node.send(node_scope).stats_by_yearweek(@activity)
    end

    @overall_administrative_stats = YearWeekStatsComparator.new
    @lastweek_administrative_stats = YearWeekStatsComparator.new
    @administrative_stats_by_week = YearWeekStatsComparator.new
    Node::ADMINISTRATIVE_NODE_SCOPES.each do |node_scope|
      @overall_administrative_stats[node_scope] = Node.send(node_scope).overall_stats(@activity)
      @lastweek_administrative_stats[node_scope] = Node.send(node_scope).latest_activity.overall_stats(@activity)
      @administrative_stats_by_week[node_scope] = Node.send(node_scope).stats_by_yearweek(@activity)
    end

  end

  def show
    @node = Node.find(params[:id])
  end

  def graphs
    if(params[:group])
      @group = Group.find(params[:group])
    end

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

  def details
    @node_scope = params[:node_scope]
    if(!Node::NODE_SCOPES.include?(@node_scope))
      @node_scope = 'all_nodes'
    end

    # todo: contributor, tags
    if(@group)
      scope = @group.nodes.send(@node_scope)
    else
      scope = Node.send(@node_scope)
    end

    @page_title_display = @page_title = "#{display_node_scope} Details"
    @endpoint = display_node_scope

    if(@group)
      @page_title += " - Group ##{@group.id}"
      @page_title_display += " for #{@group.name}"
    end

    @activity_stats = YearWeekStatsComparator.new
    NodeActivity::ACTIVITIES.each do |activity|
      @activity_stats[activity] = scope.stats_by_yearweek(activity)
    end

  end

  def list
    @node_scope = params[:node_scope]
    if(!Node::NODE_SCOPES.include?(@node_scope))
      @node_scope = 'all_nodes'
    end

    # todo: contributor, tags
    if(@group)
      scope = @group.nodes.send(@node_scope)
    else
      scope = Node.send(@node_scope)
    end

    # order_by
    if(params[:order_by] and Node.column_names.include?(params[:order_by]))
      @order_by = params[:order_by]
    else
      @order_by = 'created_at'
    end

    # direction
    if(params[:direction] and %w[asc desc].include?(params[:direction]))
      @direction = params[:direction]
    else
      @direction = 'asc'
    end

    @page_title_display = @page_title = "#{display_node_scope} Node List"
    @endpoint = "Node List"

    if(@group)
      @page_title += " - Group ##{@group.id}"
      @page_title_display += " for #{@group.name}"
    end


    @nodelist = scope.order("#{@order_by} #{@direction}").page(params[:page])

  end

  protected

  def display_node_scope
    @node_scope.gsub('_',' ').titleize
  end

  def check_for_group
    if(params[:group_id])
      @group = Group.find(params[:group_id])
    end
    true
  end

end