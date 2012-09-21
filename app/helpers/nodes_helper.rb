# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file

module NodesHelper

	def node_scope_label(node_scope)
		if(node_scope == 'all_nodes')
			'All Content'
		else
			node_scope.capitalize
		end
	end

	def activity_scope_label(activity_scope)
		if(activity_scope == 'all_activity')
			'All'
		else
			activity_scope.capitalize
		end
	end

	def node_title_display(node,options = {})
		link_to(node.display_title(options),node_path(node)).html_safe
	end

	def node_page_title_display(node,options = {})
		if(node.has_page?)
			link_to("Page ##{node.page.id}",page_path(node.page)).html_safe
		else
			'not published'
		end
	end

	def graph_nav_li(activity)
		listclass = 'active' if activity == @activity
		if(activity == NodeActivity::ALL_ACTIVITY)
			label = 'All'
		else
			label = activity.pluralize.capitalize
		end
		nav_li = '<li'
		if(listclass.present?)
			nav_li += " class=#{listclass}"
		end
		nav_li += '>'
		nav_li += link_to(label,graphs_nodes_path(:node_scope => @node_scope, :activity => activity))
		nav_li += '</li>'
		nav_li.html_safe
	end

	def overall_c_i_c_stats(node_scope,activity_scope = NodeActivity::ALL_ACTIVITY)
		if(@group.nil?)
      stats_scope = Node.send(node_scope)
    else
      stats_scope = @group.nodes.send(node_scope)
    end

    stats = stats_scope.overall_stats(activity_scope)
    returnstring = <<-END
    <p><span class='mednumber'>#{stats[:contributions]}</span> contributions</p>
    <p>of <span class='mednumber'>#{stats[:items]}</span> items</p>
    <p>by <span class='mednumber'>#{stats[:contributors]}</span> contributors</p>
    END
    returnstring.html_safe
  end

	def last_week_c_i_c_stats(node_scope,activity_scope = NodeActivity::ALL_ACTIVITY)
		if(@group.nil?)
      stats_scope = Node.send(node_scope)
    else
      stats_scope = @group.nodes.send(node_scope)
    end

    stats = stats_scope.latest_activity.overall_stats(activity_scope)
    returnstring = <<-END
    <p><span class='mednumber'>#{stats[:contributions]}</span> contributions</p>
    <p>of <span class='mednumber'>#{stats[:items]}</span> items</p>
    <p>by <span class='mednumber'>#{stats[:contributors]}</span> contributors</p>
    END
    returnstring.html_safe
  end




end
