# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

module YearWeek
  
  def yearweek_string(year,week)
    "#{year}" + "%02d" % week 
  end
  
  def yearweek(year,week)
    yearweek_string(year,week).to_i
  end
  
  def date_pair_for_year_week(year,week)
    # no exception catching, going to let it blow up if year,week is invalid
    [Date.commercial(year,week,1),Date.commercial(year,week,7)]
  end
  
  def year_week_for_date(date)
    [date.cwyear,date.cweek]
  end
  
  def previous_year_week(year,week)
    (sow,eow) = self.date_pair_for_year_week(year,week)
    previous = sow - 1.day
    [previous.cwyear,previous.cweek]
  end
  
  def previous_year_weeks(year,week,count)
    (sow,eow) = self.date_pair_for_year_week(year,week)
    previous_date_end = sow - 1.day
    previous_date_start = (previous_date_end - count.week) + 1.day
    self.year_weeks_between_dates(previous_date_start,previous_date_end)
  end
  
  
  def next_year_weeks(year,week,count)
    (sow,eow) = self.date_pair_for_year_week(year,week)
    next_date_start = eow + 1.day
    next_date_end = (next_date_start + count.week) - 1.day
    self.year_weeks_between_dates(next_date_start,next_date_end)
  end
  
  
  
  def next_year_week(year,week)
    (start_date,end_date) = self.date_pair_for_year_week(year,week)
    next_date = end_date + 1
    self.year_week_for_date(next_date)
  end
  
  def last_year_week
    last_week_date = Date.today - 7
    self.year_week_for_date(last_week_date)
  end
  
  
  def year_weeks_between_dates(start_date,end_date)
    # construct a set of year-weeks given the start and end dates
    cweek = start_date.cweek
    cwyear = start_date.cwyear
    loop_week_eow = Date.commercial(cwyear,cweek,7)
    yearweeks = []
    while(loop_week_eow <= end_date)
      yearweeks << [loop_week_eow.cwyear,loop_week_eow.cweek]
      loop_week_eow += 1.week
    end
    yearweeks
  end
  
  
  
end