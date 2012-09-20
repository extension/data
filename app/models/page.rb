# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Page < ActiveRecord::Base
  extend CacheTools
  extend YearWeek
  has_many :analytics
  has_many :page_taggings
  has_many :tags, :through => :page_taggings
  has_many :groups, :through => :tags
  belongs_to :node
  has_many :page_stats
  has_many :page_diffs
  has_one :page_total
  has_many :meta_contributors, :through => :node, :source => :meta_contributors

  # index settings
  NOT_INDEXED = 0
  INDEXED = 1
  NOT_GOOGLE_INDEXED = 2

  PERCENTILES = [99,95,90,75,50,25,10]
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
  scope :last_week_view_ordered, lambda{
    yearweek = Analytic.latest_yearweek
    joins(:page_diffs).where("page_diffs.yearweek = ?",yearweek).order("page_diffs.views DESC")
  }


  def display_title(options = {})
    truncate_it = options[:truncate].nil? ? true : options[:truncate]

    if(self.title.blank?)
      display_title = '(blank)'
    elsif(truncate_it)
      display_title = self.title.truncate(80, :separator => ' ')
    else
      display_title = self.title
    end
    display_title
  end

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
    start_date = self.created_at.to_date
    Analytic.year_weeks_from_date(start_date)
  end

  def last_diff
    if(!@last_diff)
      (year,week) = Analytic.latest_year_week
      @last_diff = self.page_diffs.by_year_week(year,week).first
    end
    @last_diff
  end

  def last_percentile
    # overall
    (year,week) = Analytic.latest_year_week
    overall_percentiles = Percentile.overall_percentile_for_year_week_datatype(year,week,self.datatype)
    ld = self.last_diff
    if(ld.nil?)
      nil
    else
      views = ld.views
      Percentile::TRACKED.each do |pct|
        column_name = "pct_#{pct}"
        if(views >= overall_percentiles.send(column_name))
          return pct
        end
      end
      return 0
    end
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

  def self.earliest_created_at
    with_scope do
      self.minimum(:created_at)
    end
  end

  def self.pagecount_for_year_week(year,week)
    yearweek = self.yearweek(year,week)
    with_scope do
      self.where("YEARWEEK(#{self.table_name}.created_at,3) <= ?",yearweek).count
    end
  end


  def self.page_counts_by_yearweek
    with_scope do
      yearweek_condition = "YEARWEEK(#{self.table_name}.created_at,3)"
      pagecounts = self.group(yearweek_condition).count
    end
  end

  def self.page_totals_by_yearweek(cache_options = {})
    pagetotals = {}
    cache_key = self.get_cache_key(__method__,{scope_sql: current_scope.to_sql})
    Rails.cache.fetch(cache_key,cache_options) do
      with_scope do
        eca = self.earliest_created_at
        if(eca.blank?)
          return pagetotals
        end

        yearweek_condition = "YEARWEEK(#{self.table_name}.created_at,3)"
        pagecounts = self.page_counts_by_yearweek
        yearweeks = Analytic.year_weeks_from_date(eca.to_date)
        yearweeks.each do |year,week|
          yearweek = self.yearweek(year,week)
          pagetotals[yearweek] = pagecounts.select{|yearweek,count| yearweek <= self.yearweek(year,week)}.values.sum
        end
      end
      pagetotals
    end
  end

  def self.stats_by_yearweek(metric,cache_options = {})
    stats = YearWeekStats.new
    cache_key = self.get_cache_key(__method__,{metric: metric, scope_sql: current_scope.to_sql})
    Rails.cache.fetch(cache_key,cache_options) do
      with_scope do
        eca = self.earliest_created_at
        if(eca.blank?)
          return stats
        end

        metric_by_yearweek = self.joins(:page_stats).group('page_stats.yearweek').sum("page_stats.#{metric}")
        metric_counts_by_yearweek =  self.joins(:page_stats).group('page_stats.yearweek').count("page_stats.#{metric}")
        year_weeks = Analytic.year_weeks_from_date(eca.to_date)
        pagetotals = self.page_totals_by_yearweek

        year_weeks.each do |year,week|
          yearweek = self.yearweek(year,week)
          stats[yearweek] = {}
          pages = pagetotals[yearweek] || 0
          total = metric_by_yearweek[yearweek] || 0
          seen = metric_counts_by_yearweek[yearweek] || 0

          stats[yearweek]['pages'] = pages
          stats[yearweek]['seen'] = seen
          stats[yearweek]['total'] = total

          per_page = ((pages > 0) ? total / pages : 0)
          stats[yearweek]['per_page'] = per_page

          previous_year_key = self.yearweek(year-1,week)
          (previous_year,previous_week) = self.previous_year_week(year,week)
          previous_week_key = self.yearweek(previous_year,previous_week)

          previous_week_total = (metric_by_yearweek[previous_week_key]  ? metric_by_yearweek[previous_week_key] : 0)
          stats[yearweek]['previous_week_total'] = previous_week_total
          previous_year_total = (metric_by_yearweek[previous_year_key]  ? metric_by_yearweek[previous_year_key] : 0)
          stats[yearweek]['previous_year_total'] = previous_year_total

          previous_week = ((pagetotals[previous_week_key] and pagetotals[previous_week_key] > 0) ? previous_week_total / pagetotals[previous_week_key] : 0)
          stats[yearweek]['previous_week'] = previous_week
          previous_year = ((pagetotals[previous_year_key] and  pagetotals[previous_year_key] > 0) ? total / pagetotals[previous_year_key] : 0)
          stats[yearweek]['previous_year'] = previous_year


          # pct_change
          if(previous_week == 0)
            stats[yearweek]['pct_change_week'] = nil
          else
            stats[yearweek]['pct_change_week'] = (per_page - previous_week) / previous_week
          end

          if(previous_year == 0)
            stats[yearweek]['pct_change_year'] = nil
          else
            stats[yearweek]['pct_change_year'] = (per_page - previous_year) / previous_year
          end
        end
      end
      stats
    end
  end

  def self.percentiles_by_yearweek(metric,options = {},cache_options = {})
    percentiles = options[:percentiles] || PERCENTILES
    seenonly = options[:seenonly].nil? ? false : options[:seenonly]
    cache_key = self.get_cache_key(__method__,{metric: metric, scope_sql: current_scope.to_sql, percentiles: percentiles, seenonly: seenonly})
    Rails.cache.fetch(cache_key,cache_options) do
      returnpercentiles = YearWeekStats.new
      returnpercentiles[:flags] = {percentiles: true}
      set_group_concat_size_query = "SET SESSION group_concat_max_len = #{Settings.group_concat_max_len};"
      self.connection.execute(set_group_concat_size_query)
      with_scope do
        eca = self.earliest_created_at
        if(eca.blank?)
          return stats
        end

        week_stats_query = self.joins(:page_stats).group('page_stats.yearweek').select("page_stats.yearweek as yearweek, GROUP_CONCAT(page_stats.#{metric}) as distribution")
        year_weeks = Analytic.year_weeks_from_date(eca.to_date)
        pagetotals = self.page_totals_by_yearweek(cache_options)

        weekstats_by_yearweek = {}
        week_stats_query.each do |ws|
          weekstats_by_yearweek[ws.yearweek] = ws.distribution.split(',').map{|i| i.to_f}
        end

        year_weeks.each do |year,week|
          yearweek = self.yearweek(year,week)
          returnpercentiles[yearweek] = {}
          pagecount = pagetotals[yearweek] || 0
          distribution = weekstats_by_yearweek[yearweek] || []
          seen = distribution.length
          if((pagecount > seen) and !seenonly)
            emptyset = Array.new((pagecount - seen),0)
            distribution += emptyset
          end
          distribution.sort!
          returnpercentiles[yearweek][:total] = pagecount
          returnpercentiles[yearweek][:seen] = seen
          distributionsum = distribution.sum
          returnpercentiles[yearweek][:mean] = (pagecount > 0 ? distributionsum / pagecount : 0 )
          percentiles.each do |percentile|
            returnpercentiles[yearweek][percentile] = distribution.nist_percentile(percentile)
          end
        end # year_week loop
      end # scoped
      returnpercentiles
    end # cache
  end



  def traffic_stats_data(showrolling = true)
    returndata = []
    upv_data = []
    rolling_data = []
    week_stats = {}
    self.week_stats.order('yearweek').map do |ws|
      yearweek_string = "#{ws.year}-" + "%02d" % ws.week
      week_stats[yearweek_string] = ws.unique_pageviews
    end

    year_weeks = self.eligible_year_weeks
    weekcount = 0
    running_upv = 0
    year_weeks.each do |year,week|
      weekcount +=1
      yearweek_string = "#{year}-" + "%02d" % week
      date = self.class.year_week_date(year,week)
      upv = week_stats[yearweek_string].nil? ? 0 : week_stats[yearweek_string]
      running_upv = running_upv+upv
      rolling_data << [date,(running_upv / weekcount)]
      upv_data << [date,upv]
    end
    if(showrolling)
      returndata = [upv_data,rolling_data]
    else
      returndata = [upv_data]
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
      date = self.year_week_date(year,week)
      upv = week_stats[yearweek_string].nil? ? 0 : week_stats[yearweek_string]
      returndata << [date,upv]
    end
    returndata
  end



  def self.traffic_stats_data_by_datatype_with_percentiles(datatype)
    percentiles = Percentile.overall_percentile_data_by_datatype(datatype)
    averages = self.traffic_stats_data_by_datatype(datatype)

    data = []
    data << averages
    Settings.display_percentiles.each do |pct|
      data << percentiles[pct]
    end
    labels = ['Average Views'] + Settings.display_percentiles_labels
    [labels,data]
  end

  def stats_for_week
    (year,week) = Analytic.latest_year_week
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
    returndata = {}
    (year,week) = Analytic.latest_year_week
    td = TotalDiff.by_datatype(datatype).by_year_week(year,week).overall.first
    recent = td.recent_pct_change.nil? ? nil : td.recent_pct_change / Settings.recent_weeks
    average = TotalDiff.by_datatype(datatype).overall.average(:views)
    weeks = TotalDiff.by_datatype(datatype).overall.count
    pages = td.pages
    new_pages = td.pages - td.pages_previous_week

    pctile = Percentile.by_datatype(datatype).by_year_week(year,week).overall.first

    returndata[:pages] = pages
    returndata[:new_pages] = new_pages
    returndata[:views] =  td.views

    returndata[:change_week] = td.pct_change_week
    returndata[:change_year] = td.pct_change_year
    returndata[:recent_change] = recent
    returndata[:average] = average
    returndata[:weeks] = weeks
    returndata[:seen] = pctile.seen
    Percentile::TRACKED.each do |pct|
      column_name = "pct_#{pct}"
      returndata[column_name.to_sym] = pctile.send(column_name)
    end
    returndata
  end


  def self.graph_data_by_datatype(datatype)
    returndata = {}
    return_pagegrowth = []
    return_views = []
    return_change = []
    return_rolling = []
    return_seen_pct = []

    week_stats = {}
    TotalDiff.by_datatype(datatype).overall.order('yearweek').map do |ws|
      yearweek_string = "#{ws.year}-" + "%02d" % ws.week
      week_stats[yearweek_string] = {:pages => ws.pages, :views => ws.views, :change => ws.pct_change_week}
    end

    Percentile.by_datatype(datatype).overall.order('yearweek').map do |pctile|
      yearweek_string = "#{pctile.year}-" + "%02d" % pctile.week
      week_stats[yearweek_string] ||= {}
      if(pctile.total > 0)
        week_stats[yearweek_string][:seen_pct] = (pctile.seen / pctile.total)
      else
        week_stats[yearweek_string][:seen_pct] = 0
      end
      Percentile::TRACKED.each do |pct|
        column_name = "pct_#{pct}"
        week_stats[yearweek_string][column_name] = pctile.send(column_name)
      end
    end


    start_date = Page.by_datatype(datatype).minimum(:created_at).to_date
    year_weeks = Analytic.year_weeks_from_date(start_date)
    views_total = 0
    loopcount = 0
    year_weeks.each do |year,week|
      loopcount += 1
      yearweek_string = "#{year}-" + "%02d" % week
      date = self.year_week_date(year,week)
      if(week_stats[yearweek_string].nil?)
        views = 0
        change = 0
        pages = 0
        seen_pct = 0
      else
        views = week_stats[yearweek_string][:views].nil? ? 0 : week_stats[yearweek_string][:views]
        change = week_stats[yearweek_string][:change].nil? ? 0 : week_stats[yearweek_string][:change]
        pages = week_stats[yearweek_string][:pages].nil? ? 0 : week_stats[yearweek_string][:pages]
        seen_pct = week_stats[yearweek_string][:seen_pct].nil? ? 0 : week_stats[yearweek_string][:seen_pct]
      end

      views_total += views
      rolling = (views_total / loopcount)
      return_pagegrowth << [date,pages]
      return_views << [date,views]
      return_change << [date,change*100]
      return_rolling << [date,rolling]
      return_seen_pct << [date,seen_pct*100]
    end

    returndata['pagegrowth'] = [return_pagegrowth]
    returndata['views'] = [return_views]
    returndata['change'] = [return_change]
    returndata['rolling'] = [return_rolling]
    returndata['seen_pct'] = [return_seen_pct]
    returndata
  end


  def self.filtered_pagelist(params)
    yearweek = Analytic.latest_yearweek
    with_scope do
      case(params[:filter])
      when 'viewed'
        joins(:page_stats).where("page_stats.yearweek = ?",yearweek).where('page_stats.unique_pageviews > 0').order("page_stats.unique_pageviews DESC")
      when 'unviewed'
        subquery = self.joins(:page_stats).where("page_stats.yearweek = ?",yearweek).where('page_stats.unique_pageviews > 0').select('pages.id')
        self.where("id NOT IN (#{subquery.to_sql})").order('pages.created_at ASC')
      else
        includes(:page_stats).order("page_stats.unique_pageviews DESC")
      end
    end
  end

end
