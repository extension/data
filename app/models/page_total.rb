# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class PageTotal < ActiveRecord::Base
  attr_accessible :page_id, :eligible_weeks, :pageviews, :unique_pageviews, :year, :week, :entrances, :time_on_page, :exits
  

  def self.rebuild
    select_statement = <<-END
    page_id,
    SUM(pageviews) as pageviews, 
    SUM(entrances) as entrances, 
    SUM(unique_pageviews) as unique_pageviews, 
    SUM(time_on_page) as time_on_page, 
    SUM(exits) AS exits
    END
    
    (maxyear,maxweek) = WeekStat.max_yearweek    
    yearweek_string = "#{maxyear}" + "%02d" % maxweek
    
    (minyear,minweek) = Page.earliest_yearweek    
    min_yearweek_string = "#{minyear}" + "%02d" % minweek
       
    week_stats = WeekStat.select(select_statement).where("yearweek >= #{min_yearweek_string} AND yearweek <= #{yearweek_string}").group("page_id")

    week_stats_by_page = {}
    week_stats.each do |ws|
      week_stats_by_page[ws.page_id] = {}
      week_stats_by_page[ws.page_id][:pageviews] = ws.pageviews
      week_stats_by_page[ws.page_id][:unique_pageviews] = ws.unique_pageviews
      week_stats_by_page[ws.page_id][:entrances] = ws.entrances
      week_stats_by_page[ws.page_id][:time_on_page] = ws.time_on_page
      week_stats_by_page[ws.page_id][:exits] = ws.exits
    end

    Page.find_each do |page|
      create_options = {:eligible_weeks => page.eligible_weeks(true)}
      if(week_stats_by_page[page.id])
        week_stat = week_stats_by_page[page.id]
        create_options[:pageviews] = week_stat[:pageviews]
        create_options[:unique_pageviews] = week_stat[:unique_pageviews]
        create_options[:entrances] = week_stat[:entrances]
        create_options[:time_on_page] = week_stat[:time_on_page]
        create_options[:exits] = week_stat[:exits]
      else
        create_options[:pageviews] = 0
        create_options[:unique_pageviews] = 0
        create_options[:entrances] = 0
        create_options[:time_on_page] = 0
        create_options[:exits] = 0
      end
      
      if(total = self.find_by_page_id(page.id))
        total.update_attributes(create_options)
      else
        self.create(create_options.merge({:page_id => page.id}))
      end
    end
  end

end
