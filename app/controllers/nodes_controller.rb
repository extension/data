# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class NodesController < ApplicationController

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

end