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

  def traffic_chart
    @page = Page.find_by_id(params[:id])
    
    
    data_table = GoogleVisualr::DataTable.new    
    data_table.new_column('string', 'Week')
    data_table.new_column('number', 'UniquePageviews')
    
    week_stats = {}
    @page.week_stats.order('yearweek').map do |ws|
      yearweek_string = "#{ws.year}-" + "%02d" % ws.week 
      week_stats[yearweek_string] = ws.unique_pageviews
    end
    
    year_weeks = @page.eligible_year_weeks
    data_table.add_rows(year_weeks.size)
    row_count = 0
    year_weeks.each do |year,week|
      yearweek_string = "#{year}-" + "%02d" % week 
      data_table.set_cell(row_count,0,yearweek_string)
      upv = week_stats[yearweek_string].nil? ? 0 : week_stats[yearweek_string]
      data_table.set_cell(row_count,1,upv)
      row_count += 1
    end
  
    options = { :width => 800, :height => 180,  :legend => 'bottom', :pointSize => 0 }
    @chart = GoogleVisualr::Interactive::LineChart.new(data_table, options)
    return render(:layout => false)
  end

end