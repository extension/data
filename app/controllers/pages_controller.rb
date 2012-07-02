# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class PagesController < ApplicationController
  
  def index
  end
  
  def show
    @page = Page.includes(:node).find(params[:id])
  end
  
  def group
    @group = Group.find(params[:id])
  end
  
  def graphs
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      # for now, error later
      @datatype = 'Article'
    end
    @graph_data = Page.graph_data_by_datatype(@datatype)
    (@percentiles_labels,@percentiles_data) = Page.traffic_stats_data_by_datatype_with_percentiles(@datatype)
  end

  def traffic_chart
    @page = Page.find_by_id(params[:id])
    
    
    data_table = GoogleVisualr::DataTable.new    
    data_table.new_column('date', 'Date')
    data_table.new_column('number', 'Views')
    
    week_stats = {}
    @page.week_stats.order('yearweek').map do |ws|
      yearweek_string = "#{ws.year}-" + "%02d" % ws.week 
      week_stats[yearweek_string] = ws.unique_pageviews
    end
    
    week_stats_data = @page.traffic_stats_data
    data_table.add_rows(week_stats_data.size)
    row_count = 0
    week_stats_data.each do |date,value|
      data_table.set_cell(row_count,0,date)
      data_table.set_cell(row_count,1,value)
      row_count += 1
    end
  
    options = { :width => 800, :height => 180,  :legend => 'bottom', :pointSize => 0 }
    @chart = GoogleVisualr::Interactive::LineChart.new(data_table, options)
    return render(:layout => false)
  end
  
  def panda_impact_summary
    if(!params[:weeks].nil?)
      @panda_comparison_weeks =  params[:weeks].to_i
    else
      @panda_comparison_weeks = 3
    end
    @diffs = TotalDiff.panda_impacts(@panda_comparison_weeks)
  end
  

end