# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file

module DownloadHelper

  def response_rate(response_rate)
    if(response_rate[:eligible] >= 0)
      ratio = (response_rate[:responses] / response_rate[:eligible]) * 100
      "#{number_to_percentage(ratio,precision: 1)} (#{number_with_delimiter(response_rate[:responses].to_i)} / #{number_with_delimiter(response_rate[:eligible])})".html_safe
    else
      "n/a"
    end
  end

end