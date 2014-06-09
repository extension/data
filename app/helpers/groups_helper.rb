# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2014 North Carolina State University
# === LICENSE:
# see LICENSE file

module GroupsHelper


  def groups_node_activity_graph_nav_li(activity)
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
    nav_li += link_to(label,node_graphs_group_path(id: @group.id, node_scope: @node_scope, activity: activity))
    nav_li += '</li>'
    nav_li.html_safe
  end


  def groups_node_activity_list_nav_li(activity)
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
    nav_li += link_to(label,node_activity_group_path(id: @group.id, node_scope: @node_scope, activity: activity))
    nav_li += '</li>'
    nav_li.html_safe
  end

end
