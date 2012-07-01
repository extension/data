# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
module GroupsHelper

  def jqplot_group_traffic_data_by_datatype(group,datatype) 
    group.traffic_stats_data_by_datatype(datatype).to_json.html_safe
  end
end
  
