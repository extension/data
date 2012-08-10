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

	def graph_nav_li(activity_scope)
		listclass = 'active' if activity_scope == @activity_scope
		if(activity_scope == 'all_activity')
			label = 'All Activity'
		else
			label = activity_scope.capitalize
		end
		nav_li = '<li'
		if(listclass.present?)
			nav_li += " class=#{listclass}"
		end
		nav_li += '>'
		nav_li += link_to(label,graphs_nodes_path(:node_scope => @node_scope, :activity_scope => activity_scope))
		nav_li += '</li>'
		nav_li.html_safe
	end

	def overall_c_i_c_stats(node_scope,activity_scope = 'all_activity')
		if(@group.nil?)
      stats_scope = NodeActivity.send(node_scope)
    else
      stats_scope = @group.node_activities.send(node_scope)
    end

    stats = stats_scope.stats(activity_scope)
    returnstring = <<-END
    <p><span class='mednumber'>#{stats['contributions']}</span> contributions</p>
    <p>of <span class='mednumber'>#{stats['items']}</span> items</p>
    <p>by <span class='mednumber'>#{stats['contributors']}</span> contributors</p>
    END
    returnstring.html_safe
  end

	def last_week_c_i_c_stats(node_scope,activity_scope = 'all_activity')
		if(@group.nil?)
      stats_scope = NodeActivityDiff.overall.by_n_a(node_scope,activity_scope)
    else
      stats_scope = @group.node_activity_diffs.by_n_a(node_scope,activity_scope)
    end

    stats = stats_scope.metrics_latest_week
    returnstring = <<-END
    <p><span class='mednumber'>#{stats['contributions']}</span> contributions</p>
    <p>of <span class='mednumber'>#{stats['items']}</span> items</p>
    <p>by <span class='mednumber'>#{stats['contributors']}</span> contributors</p>
    END
    returnstring.html_safe
  end




end
