# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class NodesController < ApplicationController

  TRUE_PARAMETER_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'yes','YES'].to_set
  FALSE_PARAMETER_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE','no','NO'].to_set
  

  def graphs
    if(params[:group])
      @group = Group.find(params[:group])
    end
    
    allowed_datatypes = ['all'] + Node::PUBLISHED_DATATYPES
    allowed_event_types = ['all','edits']

    @datatype = params[:datatype]
    if(!allowed_datatypes.include?(@datatype))
      # for now, error later
      @datatype = 'all'
    end

    @event_type = params[:event_type]
    if(!allowed_event_types.include?(@event_type))
      # for now, error later
      @event_type = 'all'
    end

    # the following parameters are meant to "chop" the spikes in activity at the xth percentile
    if(!params[:showmax].nil? and FALSE_PARAMETER_VALUES.include?(params[:showmax]))
      @showmax = false
    else
      @showmax = true
    end

    if(params[:maxpercentile])
      @maxpercentile = params[:maxpercentile].to_i
    else
      @maxpercentile = 95
    end

  end

end