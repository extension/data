# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Analytic < ActiveRecord::Base
  extend Garb::Model
  metrics :entrances, :pageviews, :unique_pageviews, :exits, :time_on_page
  dimensions :page_path
    
  cattr_accessor :analytics_profile  
  before_create :set_recordsignature
  before_save   :set_url_type
  
  URL_PAGE = 'page'
  URL_MIGRATED_FAQ = 'faq'
  URL_MIGRATED_EVENT = 'event'
  URL_MIGRATED_WIKI = 'wiki'
  URL_ROOT = 'root'
  URL_SEARCH = 'search'
  URL_ASK = 'ask'
  URL_OTHER = 'other'
  
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
    end
  end
      
  
  def set_recordsignature
    options = {:analytics_url => self.analytics_url, :segment => self.segment, :date => self.date.to_s}
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
  
  
  def self.import_analytics(options = {})
    segmentlabel = options[:segment_label] || 'all'
    if(segmentlabel != 'all')
      if(!segment_id = Settings.googleapps_search_segments.send('segmentlabel'))
        return 0
      end
    end
    
    date = options[:date]
            
    # get the records
    request_options = {:start_date => date, :end_date => date}
    if(options[:segment_id])
      request_options.merge!({:segment_id => options[:segment_id]})
    end
    results = self.request_google_analytics_data(request_options)
    record_count = 0
    if(!results.blank?)
      results.each do |result|
        record_options = {:date => date, :segment => segmentlabel}
        record_options[:analytics_url] = result.page_path
        record_options[:entrances] = result.entrances
        record_options[:pageviews] = result.pageviews
        record_options[:unique_pageviews] = result.unique_pageviews
        record_options[:exits] = result.exits
        record_options[:time_on_page] = result.time_on_page  
        record_options
        
        begin
          self.create(record_options)
          record_count += 1
        rescue ActiveRecord::RecordNotUnique
          options = {:segment => segmentlabel,:analytics_url => result.page_path, :date => date}
          if(record = self.find_by_recordsignature(options))
            record.update_attributes(record_options)
          end
        end
      end
    end
    record_count
  end
  
  
  
  
  
  
end