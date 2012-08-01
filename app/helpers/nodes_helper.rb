# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file

module NodesHelper

	def node_scope_label(node_scope)
		if(node_scope == 'all_nodes')
			'All'
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

	def node_contributions_display(contributions)
		list = contributions.split(',')
		list.uniq.map{|contribution| NodeActivity.event_to_s(contribution.to_i)}.join(', ').html_safe
	end

	def node_meta_contributions_display(contributions)
		list = contributions.split(',')
		list.uniq.join(', ').html_safe
	end
end
