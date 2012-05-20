# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class WeekStat < ActiveRecord::Base
  belongs_to :statable, :polymorphic => true
  attr_accessible :statable_id, :statable, :statable_type, :pageviews, :unique_pageviews, :year, :week, :entrances, :time_on_page, :exits
  
  
  def self.date_pair_for_year_week(year,week)
    # no exception catching, going to let it blow up if year,week is invalid
    [Date.commercial(year,week,1),Date.commercial(year,week,7)]
  end
  
  def self.year_weeks_from_date(start_date)
    end_date = Analytic.latest_date
    self.year_weeks_between_dates(start_date,end_date)  
  end
  
  def self.year_weeks(start_date,end_date)
    (earliest_year,earliest_week) = self.earliest_year_week(segment)
    earliest_date = self.date_pair_for_year_week(earliest_year,earliest_week)[0]
    from_date = (start_date < earliest_date) ? earliest_date : start_date
        
    (latest_year,latest_week) = self.latest_year_week(segment)
    latest_date = self.date_pair_for_year_week(latest_year,latest_week)[1]
    to_date = (end_date > latest_date) ? latest_date : end_date

    self.year_weeks_between_dates(from_date,to_date)  
  end
  
  def self.year_weeks_between_dates(start_date,end_date)
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
  
  
  def self.create_or_update_for_statable(statable,year,week)
    create_options = {}
    analytics = statable.analytics.sums_for_year_week(year,week)
    if(!analytics.blank?)
      analytic = analytics.first
      create_options[:pageviews] = analytic.pageviews
      create_options[:unique_pageviews] = analytic.unique_pageviews
      create_options[:entrances] = analytic.entrances
      create_options[:time_on_page] = analytic.time_on_page
      create_options[:exits] = analytic.exits
    else
      create_options[:pageviews] = 0
      create_options[:unique_pageviews] = 0
      create_options[:entrances] = 0
      create_options[:time_on_page] = 0
      create_options[:exits] = 0
    end

    begin
      self.create(create_options.merge({:statable => statable, :year => year, :week => week}))
    rescue ActiveRecord::RecordNotUnique
      if(weekstat = statable.week_stats.where(:year => year).where(:week => week).first)
        weekstat.update_attributes(create_options)
      end
    end
  
  end
  
  
  
  def self.mass_create_or_update_for_pages(year,week)
    select_statement = <<-END
    page_id,YEARWEEK(date) as yearweek, 
    SUM(pageviews) as pageviews, 
    SUM(entrances) as entrances, 
    SUM(unique_pageviews) as unique_pageviews, 
    SUM(time_on_page) as time_on_page, 
    SUM(exits) AS exits
    END
        
    yearweek_string = "#{year}" + "%02d" % week 
    analytics = Analytic.select(select_statement).where('page_id IS NOT NULL').where("YEARWEEK(date) = '#{yearweek_string}'").group("page_id,YEARWEEK(date)")

    analytics.each do |analytic|
      create_options = {}
      create_options[:pageviews] = analytic.pageviews
      create_options[:unique_pageviews] = analytic.unique_pageviews
      create_options[:entrances] = analytic.entrances
      create_options[:time_on_page] = analytic.time_on_page
      create_options[:exits] = analytic.exits

      begin
        self.create(create_options.merge({:statable_id => analytic.page_id, :statable_type => 'Page', :year => year, :week => week}))
      rescue ActiveRecord::RecordNotUnique
        if(weekstat = WeekStat.where(:statable_id => analytic.page_id).where(:statable_type => 'Page').where(:year => year).where(:week => week).first)
          weekstat.update_attributes(create_options)
        end
      end
    end
  end

end