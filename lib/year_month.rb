# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

module YearMonth

  def previous_year_month(year_month)
    previous_month = (Date.strptime(year_month_string(year_month),'%Y-%m') - 1.month)
    [previous_month.year,previous_month.month]
  end

  def next_year_month(year_month)
    next_month = (Date.strptime(year_month_string(year_month),'%Y-%m') + 1.month)
    [next_month.year,next_month.month]
  end

  def year_month_string(year_month)
    "#{year_month[0]}-" + "%02d" % year_month[1]
  end

  def year_months_between_dates(start_date,end_date)
    year_months = []
    # construct a set of year-months given the start and end dates
    the_end = end_date.beginning_of_month
    loop_date = start_date.beginning_of_month
    while loop_date <= the_end
      year_months << [loop_date.year,loop_date.month]
      loop_date = loop_date.next_month
    end
    year_months
  end


end