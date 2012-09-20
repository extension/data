# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class YearWeekStats < Hash
  extend YearWeek

  def to_graph_data(hashvalue,options = {})
    showrolling = options[:showrolling].blank? ? true : options[:showrolling]
    returndata = []
    value_data = []
    rolling_data = []
    self.yearweeks.each do |yearweek|
      yearweek_date = self.class.yearweek_date(yearweek)
      if(showrolling)
        # if no rolling value, mark showrolling false
        if self[yearweek]['rolling'].nil?
          showrolling = false
        else
          rolling = self[yearweek]['rolling']
          rolling_data << [yearweek_date,rolling]
        end
      end
      value = self[yearweek][hashvalue] || 0
      value_data << [yearweek_date,value]
    end
    if(showrolling)
      returndata = [value_data,rolling_data]
    else
      returndata = [value_data]
    end
    returndata
  end

  def max_for_hashvalue(hashvalue,nearest = nil)
    distribution = []
    self.yearweeks.each do |yearweek|
      if(!self[yearweek][hashvalue].nil?)
        distribution << self[yearweek][hashvalue]
      end
    end
    max = distribution.max
    if(nearest)
      max = max + nearest - (max % nearest)
    end
    max
  end

  def yearweeks
    if(!@yearweeks)
      @yearweeks = self.keys.reject{|keyname| keyname == :flags}.sort
    end
    @yearweeks
  end

  def flags
    if(self[:flags])
      self[:flags]
    else
      {}
    end
  end

end