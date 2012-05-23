# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class WeekTotal < ActiveRecord::Base
  belongs_to :resource_tag
  attr_accessible :resource_tag, :resource_tag_id, :pages, :pageviews, :unique_pageviews, :datatype, :year, :week, :entrances, :time_on_page, :exits

  
  def self.rebuild_all(options = {})
    tag = options[:tag]
    if(tag.nil?)
      tag_id = 0
      week_stats = WeekStat.sums_by_yearweek
    else
      tag_id = tag.id
      week_stats = tag.week_stats.sums_by_yearweek
    end
    
    week_stats_by_yearweek = {}
    week_stats.each do |ws|
      yearweek = "#{ws.year}-#{ws.week}"
      week_stats_by_yearweek[yearweek] = {}
      week_stats_by_yearweek[yearweek][:pageviews] = ws.pageviews
      week_stats_by_yearweek[yearweek][:unique_pageviews] = ws.unique_pageviews
      week_stats_by_yearweek[yearweek][:entrances] = ws.entrances
      week_stats_by_yearweek[yearweek][:time_on_page] = ws.time_on_page
      week_stats_by_yearweek[yearweek][:exits] = ws.exits
    end
    
    
    start_date = Page.minimum(:created_at).to_date
    yearweeks = WeekStat.year_weeks_from_date(start_date)
    yearweeks.each do |year,week|
      
      pages = (tag.nil?) ? Page.pagecount_for_yearweek(year,week) : tag.pages.pagecount_for_yearweek(year,week)
      yearweek = "#{year}-#{week}"
      
      create_options = {:pages => pages}
      if(week_stats_by_yearweek[yearweek])
        week_stat = week_stats_by_yearweek[yearweek]
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
      
      begin
        self.create(create_options.merge({:resource_tag_id => tag_id, :year => year, :week => week, :datatype => 'all'}))
      rescue ActiveRecord::RecordNotUnique
        if(weektotal = WeekTotal.where(:resource_tag_id => tag_id).where(:datatype => 'all').where(:year => year).where(:week => week).first)
          weektotal.update_attributes(create_options)
        end
      end
    end
  end
  
  
  def self.rebuild_by_datatype(options = {})
    datatypes = Page.datatypes
    tag = options[:tag]
    if(tag.nil?)
      tag_id = 0
      week_stats = WeekStat.sums_by_yearweek_by_datatype
    else
      tag_id = tag.id
      week_stats = tag.week_stats.sums_by_yearweek_by_datatype
    end
    
    week_stats_by_yearweek = {}
    week_stats.each do |ws|
      key_string = "#{ws.year}-#{ws.week}-#{ws.datatype}"
      week_stats_by_yearweek[key_string] = {}
      week_stats_by_yearweek[key_string][:pageviews] = ws.pageviews
      week_stats_by_yearweek[key_string][:unique_pageviews] = ws.unique_pageviews
      week_stats_by_yearweek[key_string][:entrances] = ws.entrances
      week_stats_by_yearweek[key_string][:time_on_page] = ws.time_on_page
      week_stats_by_yearweek[key_string][:exits] = ws.exits
    end
    
    
    start_date = Page.minimum(:created_at).to_date
    yearweeks = WeekStat.year_weeks_from_date(start_date)
    yearweeks.each do |year,week|
      datatypes.each do |datatype|
        pages = (tag.nil?) ? Page.by_datatype(datatype).pagecount_for_yearweek(year,week) : tag.pages.by_datatype(datatype).pagecount_for_yearweek(year,week)
        key_string = "#{year}-#{week}-#{datatype}"
      
        create_options = {:pages => pages}
        if(week_stats_by_yearweek[key_string])
          week_stat = week_stats_by_yearweek[key_string]
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
      
        begin
          self.create(create_options.merge({:resource_tag_id => tag_id, :year => year, :week => week, :datatype => datatype}))
        rescue ActiveRecord::RecordNotUnique
          if(weektotal = WeekTotal.where(:resource_tag_id => tag_id).where(:datatype => datatype).where(:year => year).where(:week => week).first)
            weektotal.update_attributes(create_options)
          end
        end
      end # datatype loop
    end # year-week loop
  end
  
end