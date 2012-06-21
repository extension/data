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
      number_to_percentage(value * 100, :precision => 2)
    else
      value
    end
  end
  
  
end
