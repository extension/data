# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class YearWeekStats < Hash
  extend YearWeek

  def to_graph_data(hashvalue,showrolling = true)
    returndata = []
    value_data = []
    rolling_data = []
    self.keys.sort.each do |yearweek|
      yearweek_date = self.class.yearweek_date(yearweek)
      rolling_data << [yearweek_date,(self[yearweek]['rolling'])]
      value_data << [yearweek_date,self[yearweek][hashvalue]]
    end
    if(showrolling)
      returndata = [value_data,rolling_data]
    else
      returndata = [value_data]
    end
    returndata
  end

  def max_for_hashvalue(hashvalue,nearest = nil)
    max = self.values.collect{|yearweek_data| yearweek_data[hashvalue]}.max
    if(nearest)
      max = max + nearest - (max % nearest)
    end
    max
  end

end