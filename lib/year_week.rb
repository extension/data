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
  
  def date_pair_for_year_week(year,week)
    # no exception catching, going to let it blow up if year,week is invalid
    [Date.commercial(year,week,1),Date.commercial(year,week,7)]
  end
  
  def year_week_for_date(date)
    [date.cwyear,date.cweek]
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
  
  
  def latest_year_week
    if(yearweek = self._latest_year_week)
      latest_year = yearweek[0]
      latest_week = yearweek[1]
    else
      (latest_year,latest_week) = self.last_year_week
    end
    [latest_year,latest_week]
  end
    
    
  def _latest_year_week
    year = self.maximum(:year)
    if(year.nil?)
      nil
    else
      week = self.where(:year => year).maximum(:week)
      if(week.nil?)
        nil
      else
        [year,week]
      end
    end
  end
  
  
  def earliest_year_week(fallbackdate = Date.parse(Settings.googleapps_traffic_start))
    if(yearweek = self._earliest_year_week)
     earliest_year = yearweek[0]
     earliest_week = yearweek[1]
    else
     (earliest_year,earliest_week) = self.year_week_for_date(fallbackdate)
    end
    [earliest_year,earliest_week]
  end
  
  def _earliest_year_week
    year = self.minimum(:year)
    if(year.nil?)
      nil
    else
      week = self.where(:year => year).minimum(:week)
      if(week.nil?)
        nil
      else
        [year,week]
      end
    end
  end
    
  def has_records_for_year_week?(year,week)
    count = self.where(:year => year).where(:week => week).count
    (count > 0)
  end
  
  def all_year_weeks
    (earliest_year,earliest_week) = self.earliest_year_week
    (latest_year,latest_week) = self.latest_year_week
          
    start_date = self.date_pair_for_year_week(earliest_year,earliest_week)[0]
    end_date = self.date_pair_for_year_week(latest_year,latest_week)[1]
    self.year_weeks_between_dates(start_date,end_date)  
  end
  
  def year_weeks_from_date(start_date)
    (earliest_year,earliest_week) = self.earliest_year_week
    (latest_year,latest_week) = self.latest_year_week
    earliest_date = self.date_pair_for_year_week(earliest_year,earliest_week)[0]
    from_date = (start_date < earliest_date) ? earliest_date : start_date    
    end_date = self.date_pair_for_year_week(latest_year,latest_week)[1]
    self.year_weeks_between_dates(from_date,end_date)  
  end
  
  def year_weeks(start_date,end_date)
    (earliest_year,earliest_week) = self.earliest_year_week
    (latest_year,latest_week) = self.latest_year_week
      
    earliest_date = self.date_pair_for_year_week(earliest_year,earliest_week)[0]
    from_date = (start_date < earliest_date) ? earliest_date : start_date
        
    latest_date = self.date_pair_for_year_week(latest_year,latest_week)[1]
    to_date = (end_date > latest_date) ? latest_date : end_date

    self.year_weeks_between_dates(from_date,to_date)  
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