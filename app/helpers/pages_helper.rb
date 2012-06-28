# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
module PagesHelper

  def link_to_tag_with_id(tag_id)
    if(tag_id == 0)
      'All'
    elsif(tag = Tag.find_by_id(tag_id))
      "#{tag.name}"
    else
      'Unknown'
    end
  end
  
  def percentage_if_applicable(value)
    if(value.is_a?(Numeric))
      if(value > 0)
        "<span class='label label-success'>#{number_to_percentage(value * 100, :precision => 2)}</span>".html_safe
      else
        "<span class='label label-important'>#{number_to_percentage(value * 100, :precision => 2)}</span>".html_safe
      end
    else
      value
    end
  end
  
  def jqplot_page_traffic_data(page)
    page.week_stats_data.to_json.html_safe
  end
  
  def date_range_for_last_week
    (year,week) = Page.last_year_week
    (sow,eow) = Page.date_pair_for_year_week(year,week)
    "#{sow.to_s} — #{eow.to_s}".html_safe
  end
  
  def page_views_information(page)
    stats_for_week = page.stats_for_week
    output = "<p>#{stats_for_week[:views]} Views</p>"
    output += "\n"
    if(stats_for_week[:change_week])
      display = number_to_percentage(stats_for_week[:change_week] * 100, :precision => 2)
    else
      display = "n/a"
    end
    output += "\n"
    output +=  "<p>Change from previous week: #{display}</p>"
    
    if(stats_for_week[:change_year])
      display = number_to_percentage(stats_for_week[:change_year] * 100, :precision => 2)
    else
      display = "n/a"
    end
    output += "\n"
    output +=  "<p>Change from previous year: #{display}</p>"
    
    if(stats_for_week[:recent_change])
      display = number_to_percentage(stats_for_week[:recent_change] * 100, :precision => 2)
    else
      display = "n/a"
    end
    output += "\n"
    output += "<p>Trend over last #{Settings.recent_weeks} weeks: #{display}</p>"
    
    if(stats_for_week[:average])
      display = number_with_precision(stats_for_week[:average], :precision => 1)
      output += "\n"
      output += "<p>Average over #{stats_for_week[:weeks]} weeks: #{display}</p>"
    end    
    
    output.html_safe
  end
    
  
end
