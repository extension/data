# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
module ApplicationHelper

  def twitter_alert_class(type)
    baseclass = "alert"
    case type
    when :alert
      "#{baseclass} alert-warning"
    when :error
      "#{baseclass} alert-error"
    when :notice
      "#{baseclass} alert-info"
    when :success
      "#{baseclass} alert-success"
    else
      "#{baseclass} #{type.to_s}"
    end
  end

  def nav_item(path,label)
    list_item_class = current_page?(path) ? " class='active'" : ''
    "<li#{list_item_class}>#{link_to(label,path)}</li>".html_safe
  end

  def sign_class(value)
    (value > 0 ) ? 'positive' : 'negative'
  end

  def up_or_down(value)
    (value > 0 ) ? '↑'.html_safe : '↓'.html_safe
  end

  def sign_class_percentage(value)
    if(value.abs < Settings.flat_percentage)
      ''
    else
      (value > 0 ) ? 'positive' : 'negative'
    end
  end

  def up_or_down_percentage(value)
    if(value.abs < Settings.flat_percentage)
      '↔'.html_safe
    else
      (value > 0 ) ? '↑'.html_safe : '↓'.html_safe
    end
  end

  # make sure @direction and @order_by are set
  # before using this helper
  def sortable_th(options = {})
    column = options[:column]
    title = options[:title] || column.titleize
    link_direction = options[:direction] || 'desc'
    if(column == @order_by)
      # current direction
      css_class = "current #{@direction}"
      # flip link direction to opposite of current
      link_direction = (@direction == 'asc') ? 'desc' : 'asc'
    end
    "<th>#{link_to(title, params.merge({order_by: column, direction: link_direction}),class: css_class)}</th>".html_safe
  end


end
