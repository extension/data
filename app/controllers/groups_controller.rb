# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class GroupsController < ApplicationController
  


  def traffic_chart
    @group = Group.find_by_id(params[:id])
    
    
    data_table = GoogleVisualr::DataTable.new    
    data_table.new_column('string', 'Week')
    data_table.new_column('number', 'Views')
    
    week_stats = {}
    @group.week_stats.order('yearweek').map do |ws|
      yearweek_string = "#{ws.year}-" + "%02d" % ws.week 
      week_stats[yearweek_string] = ws.unique_pageviews
    end
    
    week_stats_data = @page.week_stats_data
    data_table.add_rows(week_stats_data.size)
    row_count = 0
    week_stats_data.each do |label,value|
      data_table.set_cell(row_count,0,label)
      data_table.set_cell(row_count,1,value)
      row_count += 1
    end
  
    options = { :width => 800, :height => 180,  :legend => 'bottom', :pointSize => 0 }
    @chart = GoogleVisualr::Interactive::LineChart.new(data_table, options)
    return render(:layout => false)
  end

end