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

    # Takes a period of time in seconds and returns it in human-readable form (down to minutes)
  # code from http://www.postal-code.com/binarycode/2007/04/04/english-friendly-timespan/
  def time_period_to_s(time_period,abbreviated=false,defaultstring='')
   out_str = ''
   interval_array = [ [:weeks, 604800], [:days, 86400], [:hours, 3600], [:minutes, 60], [:seconds, 1] ]
   interval_array.each do |sub|
    if time_period >= sub[1] then
      time_val, time_period = time_period.divmod( sub[1] )
      if(abbreviated)
        name = sub[0].to_s.first
        ( sub[0] != :seconds ? out_str += ", " : out_str += " " ) if out_str != ''
      else
        time_val == 1 ? name = sub[0].to_s.chop : name = sub[0].to_s
        ( sub[0] != :seconds ? out_str += ", " : out_str += " and " ) if out_str != ''
      end
      out_str += time_val.to_i.to_s + " #{name}"
    end
   end
   if(out_str.nil? or out_str.empty?)
     return defaultstring
   else
     return out_str
   end
  end


  # code from: https://github.com/ripienaar/mysql-dump-split
  def humanize_bytes(bytes,defaultstring='')
    if(!bytes.nil? and bytes != 0)
      units = %w{B KB MB GB TB}
      e = (Math.log(bytes)/Math.log(1024)).floor
      s = "%.1f"%(bytes.to_f/1024**e)
      s.sub(/\.?0*$/,units[e])
    else
      defaultstring
    end
  end



end
