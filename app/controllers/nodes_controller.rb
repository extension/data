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