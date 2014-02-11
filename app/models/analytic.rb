# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Analytic < ActiveRecord::Base
  extend Garb::Model
  include CacheTools
  extend YearWeek
  metrics :entrances, :pageviews, :unique_pageviews, :exits, :time_on_page, :visitors, :new_visits
  dimensions :page_path

  cattr_accessor :analytics_profile
  before_create :set_recordsignature
  before_save   :set_url_type

  scope :by_year_week, lambda {|year,week| {:conditions => ["year = ? and week= ?",year,week] } }

  URL_PAGE = 'page'
  URL_MIGRATED_FAQ = 'faq'
  URL_MIGRATED_EVENT = 'event'
  URL_MIGRATED_WIKI = 'wiki'
  URL_ROOT = 'root'
  URL_SEARCH = 'search'
  URL_ASK = 'ask'
  URL_OTHER = 'other'
  URL_LANDING = 'landing'

  def set_url_type
    if(analytics_url == '/')
      self.url_type = URL_ROOT
    elsif(analytics_url =~ %r{^/pages/(\d+)\/})
      self.url_type = URL_PAGE
      self.url_page_id = $1
    elsif(analytics_url =~ %r{^/pages/(\d+)$})
      self.url_type = URL_PAGE
      self.url_page_id = $1
    elsif(analytics_url =~ %r{^/article/(\d+)})
      self.url_type = URL_PAGE
      self.url_page_id = $1
    elsif(analytics_url =~ %r{^/faq/(\d+)})
      self.url_type = URL_MIGRATED_FAQ
      self.url_migrated_id = $1
    elsif(analytics_url=~ %r{^/events/(\d+)$} or analytics_url=~ %r{^/events/(\d+)\?})
      self.url_type = URL_MIGRATED_EVENT
      self.url_migrated_id = $1
    elsif(analytics_url =~ %r{^/pages/(.+)} or analytics_url =~ %r{^/articles/(.+)})
      ga_url = $1
      if(!ga_url.index('?'))
        request_uri = ga_url
      elsif(ga_url[-1,1] == '?')
        request_uri = ga_url
      else
        (request_uri,blah) = ga_url.split(%r{(.+)\?})[1,2]
      end
      if(!request_uri.blank?)
        title_to_lookup = CGI.unescape(request_uri)
        if(!title_to_lookup.valid_encoding?)
          self.url_type = URL_OTHER
        else
          if title_to_lookup =~ /\/print(\/)?$/
            title_to_lookup.gsub!(/\/print(\/)?$/, '')
          end
          self.url_type = URL_MIGRATED_WIKI
          self.url_wiki_title = title_to_lookup
        end
      else
        self.url_type = URL_OTHER
      end
    elsif(analytics_url =~ %r{^/ask/(\w+)})
      self.url_widget_id = $1
      self.url_type = URL_ASK
    elsif(analytics_url =~ %r{^/main/search})
      self.url_type = URL_SEARCH
    elsif(analytics_url =~ %r{^/category/(.+)})
      check_for_tag($1)
    else
      check_for_tag(analytics_url)
    end
  end

  def check_for_tag(checkstring)
    paths = checkstring.split('/').reject(&:empty?)
    if(paths.size == 1)
      begin
        tagname = CGI.unescape(paths[0]).gsub('_',' ')
        if(tag = Tag.find_by_name(tagname))
          self.tag_id = tag.id
          self.url_type = URL_LANDING
        else
          self.url_type = URL_OTHER
        end
      rescue
        self.url_type = URL_OTHER
      end
    else
      self.url_type = URL_OTHER
    end
  end

  def associate_with_page
    case self.url_type
    when URL_PAGE
      page = Page.find_by_id(self.url_page_id)
    when URL_MIGRATED_FAQ
      page = Page.find_by_migrated_id(self.url_migrated_id)
    when URL_MIGRATED_EVENT
      page = Page.find_by_migrated_id(self.url_migrated_id)
    when URL_MIGRATED_WIKI
      page = Page.find_by_title_url(self.url_wiki_title)
    else
      # nothing
    end

    if(page)
      self.update_attribute(:page_id,page.id)
      return true
    else
      return false
    end
  end


  def set_recordsignature
    options = {:analytics_url => self.analytics_url, :year => self.year, :week => self.week}
    self.analytics_url_hash = self.class.recordsignature(options)
  end



  def self.recordsignature(options = {})
    keystring = []
    options.keys.map{|k|k.to_s}.sort.each do |key|
      keystring << "#{key}=#{options[key.to_sym].to_s}"
    end
    Digest::SHA1.hexdigest(keystring.join(':'))
  end

  def self.find_by_recordsignature(options = {})
    self.first(:conditions => {:analytics_url_hash => self.recordsignature(options)})
  end

  def self.google_analytics_session
    @session_token ||= Garb::Session.login(Settings.googleapps_analytics,Settings.googleapps_analytics_secret)
  end

  def self.request_google_analytics_data(options = {})
    return_results = []
    session = self.google_analytics_session
    if(!self.analytics_profile)
      # harcoded to only the first profile, the account I'm using only has access to one
      self.analytics_profile = Garb::Management::Profile.all[0]
    end

    # first resultset
    ga_options = options.merge({:limit => Settings.googleapps_analytics_limit})
    resultset = self.results(self.analytics_profile, ga_options)
    return_results = resultset.to_a
    if(resultset.total_results > Settings.googleapps_analytics_limit)
      total_request_count = (resultset.total_results / Settings.googleapps_analytics_limit.to_f).ceil
      2.upto(total_request_count) do |request_number|
        ga_options = options.merge({:limit => Settings.googleapps_analytics_limit, :offset => ((request_number - 1) * Settings.googleapps_analytics_limit) + 1 })
        resultset = self.results(self.analytics_profile, ga_options)
        return_results += resultset.to_a
      end
    end
    return_results
  end



  def self.import_analytics_for_year_week(year,week)
    if(year.nil? or week.nil?)
      0
    end

    (start_date,end_date) = self.date_pair_for_year_week(year,week)

    # get the records
    request_options = {:start_date => start_date, :end_date => end_date}
    results = self.request_google_analytics_data(request_options)
    record_count = 0
    if(!results.blank?)
      results.each do |result|
        record_options = {:year => year, :week => week, :yearweek => self.yearweek_string(year,week)}
        record_options[:analytics_url] = result.page_path
        record_options[:entrances] = result.entrances
        record_options[:pageviews] = result.pageviews
        record_options[:unique_pageviews] = result.unique_pageviews
        record_options[:exits] = result.exits
        record_options[:time_on_page] = result.time_on_page
        record_options[:visitors] = result.visitors
        record_options[:new_visits] = result.new_visits
        record_options

        begin
          self.create(record_options)
          record_count += 1
        rescue ActiveRecord::RecordNotUnique
          options = {:analytics_url => result.page_path, :year => year, :week => week}
          if(record = self.find_by_recordsignature(options))
            record.update_attributes(record_options)
          end
        end
      end
    end
    record_count
  end

  def self.associate_with_pages_for_year_week(year,week)
    pagecount = 0
    self.by_year_week(year,week).each do |analytic|
      pagecount +=1 if analytic.associate_with_page
    end
    pagecount
  end


  def self.latest_yearweek
    (year,week) = latest_year_week
    yearweek(year,week)
  end

  def self.latest_year_week(cache_options = {})
    # cachekey = self.get_cache_key(__method__)
    # Rails.cache.fetch(cachekey,cache_options) do
      if(yearweek = self._latest_year_week)
        latest_year = yearweek[0]
        latest_week = yearweek[1]
      else
        (latest_year,latest_week) = self.last_year_week
      end
      [latest_year,latest_week]
    # end
  end

  def self.latest_date
    (year,week) = self.latest_year_week
    (blah,last_date) = self.date_pair_for_year_week(year,week)
    last_date
  end

  def self._latest_year_week
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


  def self.earliest_year_week(cache_options = {})
    cachekey = self.get_cache_key(__method__)
    Rails.cache.fetch(cachekey,cache_options) do
      if(yearweek = self._earliest_year_week)
       earliest_year = yearweek[0]
       earliest_week = yearweek[1]
      else
       (earliest_year,earliest_week) = self.year_week_for_date(Date.parse(Settings.googleapps_traffic_start))
      end
      [earliest_year,earliest_week]
    end
  end

  def self._earliest_year_week
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

  def self.has_analytics_for_year_week?(year,week)
    count = self.where(:year => year).where(:week => week).count
    (count > 0)
  end

  def self.all_year_weeks
    (earliest_year,earliest_week) = self.earliest_year_week
    (latest_year,latest_week) = self.latest_year_week

    start_date = self.date_pair_for_year_week(earliest_year,earliest_week)[0]
    end_date = self.date_pair_for_year_week(latest_year,latest_week)[1]
    self.year_weeks_between_dates(start_date,end_date)
  end

  def self.year_weeks_from_date(start_date)
    (earliest_year,earliest_week) = self.earliest_year_week
    (latest_year,latest_week) = self.latest_year_week
    earliest_date = self.date_pair_for_year_week(earliest_year,earliest_week)[0]
    from_date = (start_date.nil? or start_date < earliest_date) ? earliest_date : start_date
    end_date = self.date_pair_for_year_week(latest_year,latest_week)[1]
    self.year_weeks_between_dates(from_date,end_date)
  end

  def self.year_weeks(start_date,end_date)
    (earliest_year,earliest_week) = self.earliest_year_week
    (latest_year,latest_week) = self.latest_year_week

    earliest_date = self.date_pair_for_year_week(earliest_year,earliest_week)[0]
    from_date = (start_date < earliest_date) ? earliest_date : start_date

    latest_date = self.date_pair_for_year_week(latest_year,latest_week)[1]
    to_date = (end_date > latest_date) ? latest_date : end_date

    self.year_weeks_between_dates(from_date,to_date)
  end

  def self.import_analytics
    results = {}
    latest_year_week = self._latest_year_week
    if(latest_year_week.nil?)
      year_weeks = self.all_year_weeks
    else
      next_year_week = self.next_year_week(latest_year_week[0],latest_year_week[1])
      start_date = self.date_pair_for_year_week(next_year_week[0],next_year_week[1])[0]
      end_date = (Date.today - 1)
      year_weeks = self.year_weeks_between_dates(start_date,end_date)
    end

    year_weeks.each do |year,week|
      yearweek = self.yearweek(year,week) 
      imported = self.import_analytics_for_year_week(year,week)
      associated = self.associate_with_pages_for_year_week(year,week)
      results[yearweek] = {imported: imported, associated: associated}
    end

    # force cache update for latest_year_week
    self.latest_year_week({force: true})
    results
  end

end