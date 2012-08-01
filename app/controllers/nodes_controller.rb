# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class NodesController < ApplicationController

  def show
    @node = Node.find(params[:id])
  end

  def graphs
    if(params[:group])
      @group = Group.find(params[:group])
    end
    
    @node_scope = params[:node_scope]
    if(!NodeActivity::NODE_SCOPES.include?(@node_scope))
      # for now, error later
      @node_scope = 'all_nodes'
    end

    @activity_scope = params[:activity_scope]
    if(!NodeActivity::ACTIVITY_SCOPES.include?(@activity_scope))
      # for now, error later
      @activity_scope = 'all_activity'
    end

    if(@group.nil?)
      @yearweek_stats = NodeActivity.send(@node_scope).stats_by_yearweek(@activity_scope)
    else
      @yearweek_stats = @group.node_activities.send(@node_scope).stats_by_yearweek(@activity_scope)
    end

  end

end