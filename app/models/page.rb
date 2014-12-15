# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Page < ActiveRecord::Base
  include CacheTools
  extend YearWeek
  has_many :analytics
  has_many :page_taggings
  has_many :tags, :through => :page_taggings
  has_many :groups, :through => :tags
  belongs_to :node
  has_many :page_stats
  has_many :page_totals
  has_many :meta_contributors, :through => :node, :source => :meta_contributors
  has_many :node_activities, :through => :node

  # index settings
  NOT_INDEXED = 0
  INDEXED = 1
  NOT_GOOGLE_INDEXED = 2

  PERCENTILES = [99,95,90,75,50,25,10]
  DATATYPES = ['Article','Faq']

  scope :not_ignored, where("indexed != ?",NOT_INDEXED )
  scope :indexed, where(:indexed => INDEXED)
  scope :articles, where(:datatype => 'Article')

  scope :news, where(:datatype => 'News')
  scope :faqs, where(:datatype => 'Faq')
  scope :created_since, lambda{|date| where("#{self.table_name}.created_at >= ?",date)}
  scope :from_create, where(:source => 'create')
  scope :by_datatype, lambda{|datatype|
    if(datatype != 'All')
      where(:datatype => datatype)
    end
  }

  scope :with_totals_for_metric, lambda{|metric|
    pt_columns = PageTotal.column_names.reject{|n| ['id','page_id','metric','created_at'].include?(n)}
    select_columns = pt_columns.map{|col| "page_totals.#{col} as #{col}"}
    joins(:page_totals).where('page_totals.metric = ?',metric).select("pages.*, #{select_columns.join(',')}")
  }

  scope :reviewed, lambda {
    joins(:node_activities).where('node_activities.activity = ?',NodeActivity::REVIEW_ACTIVITY).select("distinct(#{self.table_name}.id),#{self.table_name}.*")
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
    true
  end

  def self.earliest_created_at
    with_scope do
      self.minimum(:created_at)
    end
  end

  def self.page_counts_by_yearweek
    with_scope do
      yearweek_condition = "YEARWEEK(#{self.table_name}.created_at,3)"
      self.group(yearweek_condition).count("DISTINCT #{self.table_name}.id")
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

  def stats_by_yearweek(metric,cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__,{metric: metric})
      Rails.cache.fetch(cache_key,cache_options) do
        _stats_by_yearweek(metric)
      end
    else
      _stats_by_yearweek(metric)
    end
  end

  def _stats_by_yearweek(metric)
    stats = YearWeekStats.new
    metric_by_yearweek = self.page_stats.group('page_stats.yearweek').sum("page_stats.#{metric}")
    year_weeks = Analytic.year_weeks_from_date(self.created_at.to_date)
    year_weeks.each do |year,week|
      yearweek = self.class.yearweek(year,week)
      stats[yearweek] = {}
      total = metric_by_yearweek[yearweek] || 0
      seen = (metric_by_yearweek[yearweek] ? 1 : 0)

      stats[yearweek]['seen'] = seen
      stats[yearweek]['total'] = total

      previous_year_key = self.class.yearweek(year-1,week)
      (previous_year,previous_week) = self.class.previous_year_week(year,week)
      previous_week_key = self.class.yearweek(previous_year,previous_week)

      previous_week = (metric_by_yearweek[previous_week_key]  ? metric_by_yearweek[previous_week_key] : 0)
      previous_year = (metric_by_yearweek[previous_year_key]  ? metric_by_yearweek[previous_year_key] : 0)
      stats[yearweek]['previous_week'] = previous_week
      stats[yearweek]['previous_year'] = previous_year


      # pct_change
      if(previous_week == 0)
        stats[yearweek]['pct_change_week'] = nil
      else
        stats[yearweek]['pct_change_week'] = (total - previous_week) / previous_week
      end

      if(previous_year == 0)
        stats[yearweek]['pct_change_year'] = nil
      else
        stats[yearweek]['pct_change_year'] = (total - previous_year) / previous_year
      end
    end
    stats
  end



  def stats_for_week(metric,cache_options = {})
    stats = stats_by_yearweek(metric,cache_options)
    yearweek = Analytic.latest_yearweek
    weeks = self.eligible_weeks(true)
    if(stats[yearweek] and stats[yearweek]['total'] and weeks)
      average = stats.sum_for_hashvalue('total') / weeks.to_f
    else
      average = nil
    end
    stats[yearweek].merge({'average' => average, 'weeks' => weeks.round})
  end

  def self.stats_by_yearweek(metric,cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__,{metric: metric, scope_sql: current_scope ? current_scope.to_sql : ''})
      Rails.cache.fetch(cache_key,cache_options) do
        with_scope do
          _stats_by_yearweek(metric,cache_options)
        end
      end
    else
      with_scope do
        _stats_by_yearweek(metric,cache_options)
      end
    end
  end

  def self._stats_by_yearweek(metric,cache_options = {})
    stats = YearWeekStats.new
    set_group_concat_size_query = "SET SESSION group_concat_max_len = #{Settings.group_concat_max_len};"
    self.connection.execute(set_group_concat_size_query)
    with_scope do
      eca = self.earliest_created_at
      if(eca.blank?)
        return stats
      end

      eligible_page_ids = self.pluck("#{self.table_name}.id")
      metric_by_yearweek = PageStat.where("page_id IN (#{eligible_page_ids.join(',')})").group('yearweek').sum("#{metric}")
      metric_counts_by_yearweek = PageStat.where("page_id IN (#{eligible_page_ids.join(',')})").group('yearweek').count("DISTINCT page_stats.id")

      year_weeks = Analytic.year_weeks_from_date(eca.to_date)
      pagetotals = self.page_totals_by_yearweek(cache_options)


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
        previous_year = ((pagetotals[previous_year_key] and  pagetotals[previous_year_key] > 0) ? previous_year_total / pagetotals[previous_year_key] : 0)
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

  def self.percentiles_by_yearweek(metric,options = {},cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__,{metric: metric, scope_sql: current_scope ? current_scope.to_sql : '', options: options.to_yaml})
      Rails.cache.fetch(cache_key,cache_options) do
        with_scope do
          _percentiles_by_yearweek(metric,options,cache_options)
        end
      end
    else
      with_scope do
        _percentiles_by_yearweek(metric,options,cache_options)
      end
    end
  end


  def self._percentiles_by_yearweek(metric,options = {},cache_options = {})
    percentiles = options[:percentiles] || PERCENTILES
    seenonly = options[:seenonly].nil? ? false : options[:seenonly]
    returnpercentiles = YearWeekStats.new
    returnpercentiles[:flags] = {percentiles: true}
    set_group_concat_size_query = "SET SESSION group_concat_max_len = #{Settings.group_concat_max_len};"
    self.connection.execute(set_group_concat_size_query)
    with_scope do
      eca = self.earliest_created_at
      if(eca.blank?)
        return returnpercentiles
      end

      eligible_page_ids = self.pluck("#{self.table_name}.id")
      week_stats_query = PageStat.where("page_id IN (#{eligible_page_ids.join(',')})").group('yearweek').select("yearweek, GROUP_CONCAT(#{metric}) as distribution")
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
  end

  def self.filtered_pagelist(params)
    yearweek = Analytic.latest_yearweek
    with_scope do
      case(params[:filter])
      when 'viewed'
        with_totals_for_metric('unique_pageviews').where('mean >= 1')
      when 'unviewed'
        with_totals_for_metric('unique_pageviews').where('mean < 1')
      else
        with_totals_for_metric('unique_pageviews')
      end
    end
  end

  # used for sort direction verification
  def self.totals_list_columns
    pt_columns = PageTotal.column_names.reject{|n| ['id','page_id','metric','created_at'].include?(n)}
    my_columns = self.column_names
    (my_columns + pt_columns)
  end

  def self.totals_list(options = {})
    metric = options[:metric] || 'unique_pageviews'
    order_by = options[:order_by] || 'mean'
    direction = options[:direction] || 'desc'
    with_scope do
      with_totals_for_metric(metric).order("#{order_by} #{direction}")
    end
  end


  def self.top_pages(options = {})
    metric = options[:metric] || 'unique_pageviews'
    limit = options[:limit] || 3
    order_by = options[:by] || 'mean'
    with_scope do
      with_totals_for_metric(metric).order("#{order_by} DESC").limit(limit)
    end
  end

  def self.top_pages_by_percentile(percentile,options = {})
    metric = options[:metric] || 'unique_pageviews'
    value = options[:value] || 'mean'
    with_scope do
      distribution = self.joins(:page_totals).where("page_totals.metric = ?",metric).pluck("page_totals.#{value}")
      percentile_value = distribution.compact.nist_percentile(percentile)
      with_totals_for_metric(metric).where("#{value} >= ?",percentile_value)
    end
  end

  def self.tag_counts(cache_options= {})
    cache_key = self.get_cache_key(__method__)
    Rails.cache.fetch(cache_key,cache_options) do
      joins(:tags).group('tags.id').order('count_all DESC').count
    end
  end

  def self.counts_by_group_for_datatype(datatype,cache_options= {})
    cache_key = self.get_cache_key(__method__,{datatype: datatype})
    Rails.cache.fetch(cache_key,cache_options) do
      pagecounts = {}
      pagecounts['all'] = Page.by_datatype(datatype).count
      Group.launched.each do |group|
        pagecounts[group.id] = group.pages.by_datatype(datatype).count
      end
      pagecounts
    end
  end

end
