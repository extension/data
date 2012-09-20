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

  def seen_pct(stats)
    if(stats['pages'] and stats['pages'] > 0)
      seen = stats['seen'] || 0
      number_to_percentage((seen/stats['pages'])*100, precision: 1)
    else
      'n/a'
    end
  end

  def week_picker_date
    (year,week) = Analytic.latest_year_week
    (sow,eow) = Analytic.date_pair_for_year_week(year,week)

    if(@date and @date < eow)
      (at_date_year,at_date_week) = Analytic.year_week_for_date(date)
      (sow,eow) = Analytic.date_pair_for_year_week(at_date_year,at_date_week)
    end
    sow.strftime('%Y-%m-%d')
  end



  def year_week_for_last_week
    (year,week) = Analytic.latest_year_week
    "#{year} Week ##{week}".html_safe
  end


  def date_range_for_last_week
    (year,week) = Analytic.latest_year_week
    (sow,eow) = Page.date_pair_for_year_week(year,week)
    "#{sow.strftime("%b&nbsp;%d")} - #{eow.strftime("%b&nbsp;%d")}".html_safe
  end

  def pct_change(change,extraclass=nil)
    if(!change)
      'n/a'
    else
      classes = []
      classes << sign_class_percentage(change)
      if(extraclass)
        classes << extraclass
      end
      "<span class='#{classes.join(' ')}'>#{number_to_percentage(change * 100, :precision => 2)}</span>".html_safe
    end
  end


  def trend(change,extraclass=nil)
    if(!change)
      'n/a'
    else
      classes = []
      classes << sign_class_percentage(change)
      if(extraclass)
        classes << extraclass
      end
      output = "<span class='#{classes.join(' ')}'>#{up_or_down_percentage(change)}</span>"
      output += " <span class='#{classes.join(' ')}'>#{number_to_percentage(change * 100, :precision => 2)}</span>"
      output.html_safe
    end
  end


  def breadcrumb_li(matchaction)
    if(params[:action] == matchaction)
      "<li class='active'>".html_safe
    else
      "<li>".html_safe
    end
  end

  def number_list_link(number_text,params,number_class='mednumber')
    number_span = "<span class='#{number_class}'>#{number_text}</span>".html_safe
    if(@group)
      link_to(number_span,pagelist_group_path(params.merge(:id => @group.id))).html_safe
    else
      link_to(number_span,list_pages_path(params)).html_safe
    end
  end


end
