# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Page < ActiveRecord::Base
  extend YearWeek
  has_many :analytics
  has_many :page_taggings
  has_many :tags, :through => :page_taggings
  has_many :groups, :through => :tags
  belongs_to :node
  has_many :week_stats
  has_many :page_diffs
  has_one :page_total

  # index settings
  NOT_INDEXED = 0
  INDEXED = 1
  NOT_GOOGLE_INDEXED = 2


  DATATYPES = ['Article','Faq','Event','News']

  scope :not_ignored, where("indexed != ?",NOT_INDEXED )
  scope :indexed, where(:indexed => INDEXED)
  scope :articles, where(:datatype => 'Article')
  scope :articles2, conditions: { :datatype => 'Article' }

  scope :news, where(:datatype => 'News')
  scope :faqs, where(:datatype => 'Faq')
  scope :events, where(:datatype => 'Event')
  scope :created_since, lambda{|date| where("#{self.table_name}.created_at >= ?",date)}
  scope :from_create, where(:source => 'create')
  scope :by_datatype, lambda{|datatype| where(:datatype => datatype)}
  
  def self.earliest_year_week
    if(@yearweek.blank?)
      earliest_date = self.minimum(:created_at).to_date
      @yearweek = [earliest_date.cwyear,earliest_date.cweek]
    end
    @yearweek
  end      
      
  def eligible_weeks(fractional = false)
    if(fractional)
      eligible_year_weeks.size + ((7-self.created_at.to_date.cwday) / 7)
    else
      eligible_year_weeks.size
    end
  end
  
  def eligible_year_weeks
    start_date = self.created_at.to_date + 1.week
    Analytic.year_weeks_from_date(start_date)
  end
  
        
  def self.find_by_title_url(url)
   return nil unless url
   real_title = url.gsub(/_/, ' ')
   self.find_by_title(real_title)
  end

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")    
    DarmokPage.find_in_batches do |group|
      insert_values = []
      group.each do |page|
        insert_list = []
        insert_list << page.id
        insert_list << (page.migrated_id.blank? ? 0 : page.migrated_id)
        insert_list << ActiveRecord::Base.quote_value(page.datatype)
        insert_list << ActiveRecord::Base.quote_value(page.title)
        insert_list << ActiveRecord::Base.quote_value(page.url_title)
        insert_list << (page.content_length.blank? ? 0 : page.content_length)
        insert_list << (page.content_words.blank? ? 0 : page.content_words)
        insert_list << ActiveRecord::Base.quote_value(page.source_created_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(page.source_updated_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(page.source)
        insert_list << ActiveRecord::Base.quote_value(page.source_url)
        insert_list << page.indexed
        insert_list << (page.is_dpl? ? 1 : 0)
        links = page.link_counts
        insert_list << links[:total]
        insert_list << links[:external]
        insert_list << links[:local]
        insert_list << links[:internal]
        if(page.source == 'create' and page.source_url =~ %r{/node/(\d+)})
          insert_list << $1.to_i
        else
          insert_list << 0
        end
        insert_list << ActiveRecord::Base.quote_value(page.created_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(page.updated_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
  end
  
  def self.pagecount_for_yearweek(year,week)
    yearweek_string = self.yearweek_string(year,week)
    with_scope do
      self.where("YEARWEEK(#{self.table_name}.created_at,3) <= ?",yearweek_string).count
    end
  end
  
  def self.page_counts_by_yearweek
    with_scope do
      self.group("YEARWEEK(#{self.table_name}.created_at,3)").count
    end
  end
  
  
  def self.datatypes
    self.group(:datatype).pluck(:datatype)
  end
  
  def self.percentiles_for_year_week(year,week, options = {})
    percentiles = options[:percentiles] || Settings.default_percentiles
    seenonly = options[:seenonly].nil? ? false : options[:seenonly]
    yearweek_string = self.yearweek_string(year,week)
    
    returnpercentiles = {}
    with_scope do
      pagecount = self.where("YEARWEEK(#{self.table_name}.created_at,3) <= ?",yearweek_string).count
      weekstats = self.joins(:week_stats).where("week_stats.year = ?",year).where("week_stats.week = ?",week).pluck("week_stats.unique_pageviews")
      if((pagecount > weekstats.length) and !seenonly)
        emptyset = Array.new((pagecount - weekstats.length),0)
        statsarray = (weekstats + emptyset).sort
      else
        statsarray = weekstats.sort
      end
      returnpercentiles[:total] = pagecount
      returnpercentiles[:seen] = weekstats.length
      percentiles.each do |percentile|
        returnpercentiles[percentile] = statsarray.nist_percentile(percentile)
      end
    end
    returnpercentiles
  end
  
  def self.percentiles(options = {})
    percentiles = options[:percentiles] || Settings.default_percentiles
    seenonly = options[:seenonly].nil? ? false : options[:seenonly]
    
    pagecounts_by_yearweek = self.group("YEARWEEK(#{self.table_name}.created_at,3)").count
    weekstats_by_yearweek = {}
    self.joins(:week_stats).select("week_stats.yearweek as yearweek, week_stats.unique_pageviews as views").each do |ws|
      weekstats_by_yearweek[ws.yearweek] ||= []
      weekstats_by_yearweek[ws.yearweek] << ws.views
    end
    
    returnpercentiles = {}
    earliest_created_at = self.minimum(:created_at)
    if(!earliest_created_at.nil?)
      earliest_date = earliest_created_at.to_date
      year_weeks = Analytic.year_weeks_from_date(earliest_date)
      year_weeks.each do |year,week|
        yearweek = self.yearweek(year,week)
        returnpercentiles[yearweek] = {}
        pagecount = pagecounts_by_yearweek.select{|yearweek,count| yearweek <= self.yearweek(year,week)}.values.sum      
        weekstats = weekstats_by_yearweek[yearweek] || []
        if((pagecount > weekstats.length) and !seenonly)
          emptyset = Array.new((pagecount - weekstats.length),0)
          statsarray = (weekstats + emptyset).sort
        else
          statsarray = weekstats.sort
        end
        returnpercentiles[yearweek][:total] = pagecount
        returnpercentiles[yearweek][:seen] = weekstats.length
        percentiles.each do |percentile|
          returnpercentiles[yearweek][percentile] = statsarray.nist_percentile(percentile)
        end
      end
    end
    returnpercentiles
  end
  
  def traffic_stats_data
    returndata = []
    week_stats = {}
    self.week_stats.order('yearweek').map do |ws|
      yearweek_string = "#{ws.year}-" + "%02d" % ws.week 
      week_stats[yearweek_string] = ws.unique_pageviews
    end
    
    year_weeks = self.eligible_year_weeks
    year_weeks.each do |year,week|
      yearweek_string = "#{year}-" + "%02d" % week
      date = self.class.yearweek_date(year,week)
      upv = week_stats[yearweek_string].nil? ? 0 : week_stats[yearweek_string]
      returndata << [date,upv]
    end
    returndata
  end
  
  def self.traffic_stats_data_by_datatype(datatype)
    returndata = []
    week_stats = {}
    TotalDiff.by_datatype(datatype).overall.order('yearweek').map do |ws|
      yearweek_string = "#{ws.year}-" + "%02d" % ws.week 
      week_stats[yearweek_string] = ws.views
    end
    
    start_date = Page.by_datatype(datatype).minimum(:created_at).to_date
    year_weeks = Analytic.year_weeks_from_date(start_date)
    year_weeks.each do |year,week|
      yearweek_string = "#{year}-" + "%02d" % week
      date = self.yearweek_date(year,week)
      upv = week_stats[yearweek_string].nil? ? 0 : week_stats[yearweek_string]
      returndata << [date,upv]
    end
    returndata
  end  

  def stats_for_week
    (year,week) = self.class.last_year_week
    pd = self.page_diffs.by_year_week(year,week).first
    if(pd.nil?)
      views = 0
      change_week = nil
      change_year = nil
    else
      views = pd.views
      change_week = pd.pct_change_week
      change_year = pd.pct_change_year
      recent = pd.recent_pct_change.nil? ? nil : pd.recent_pct_change / Settings.recent_weeks
    end
    
    if(total_views = self.page_total.unique_pageviews and eligible_weeks = self.page_total.eligible_weeks)
      average = (total_views / eligible_weeks)
    else
      average = nil
    end
    {:views => views, :change_week => change_week, :change_year => change_year, :recent_change => recent, :average => average, :weeks => eligible_weeks.round }
  end
  
  
  def self.stats_for_week_for_datatype(datatype)
    (year,week) = self.last_year_week
    td = TotalDiff.by_datatype(datatype).by_year_week(year,week).overall.first
    recent = td.recent_pct_change.nil? ? nil : td.recent_pct_change / Settings.recent_weeks
    average = TotalDiff.by_datatype(datatype).overall.average(:views)
    weeks = TotalDiff.by_datatype(datatype).overall.count
    pages = td.pages
    new_pages = td.pages - td.pages_previous_week
    {:pages => td.pages, :new_pages => new_pages, :views => td.views, :change_week => td.pct_change_week, :change_year => td.pct_change_year, :recent_change => recent, :average => average, :weeks => weeks }
  end
  
  

    

  
  
end
