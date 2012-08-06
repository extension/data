# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class NodesController < ApplicationController

  def index


  end

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
      @stats_scope = NodeActivityDiff.overall.by_node_scope(@node_scope).by_activity_scope(@activity_scope)
    else
      @stats_scope = @group.node_activity_diffs.by_node_scope(@node_scope).by_activity_scope(@activity_scope)
    end

  end

end