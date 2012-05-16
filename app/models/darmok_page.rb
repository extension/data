# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DarmokPage < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :darmok
  self.set_table_name 'pages'
  JOINER = ", " 
  SPLITTER = Regexp.new(/\s*,\s*/)
  
  has_one :link_stat, :foreign_key => "page_id"
  
  def link_counts
    linkcounts = {:total => 0, :external => 0,:local => 0, :wanted => 0, :internal => 0, :broken => 0, :redirected => 0, :warning => 0}
    if(!self.link_stat.nil?)
      linkcounts.keys.each do |key|
        linkcounts[key] = self.link_stat.send(key)
      end
    end
    return linkcounts
  end

  def resource_tag_names
    if(!self.cached_content_tags.blank?)
      cached_tag_list = self.cached_content_tags.split(JOINER)
      global_community_content_tag_names = self.class.content_tag_list
      cached_tag_list & global_community_content_tag_names
    else
      []
    end
  end
    
  # list of publishing tags, retrieved and cached from darmok
  def self.get_content_tag_list
    taglist = []
    begin
      communitylist_json = self.fetch_url_content(self.communitylist_url('publishing'))
    rescue
      # should do something eventually
    end
    
    if(!communitylist_json.nil?)
      begin
        communitylist = ActiveSupport::JSON.decode(communitylist_json)
      rescue
        # should do something eventually
      end
    end
  
    if(!communitylist.nil?)
      communitylist['communities'].each do |communityid,communityattributes|
        taglist += communityattributes['content_tag_names'].split(SPLITTER) if(!communityattributes['content_tag_names'].blank?)
      end
    end
  
    taglist.sort
  end
  
  def self.content_tag_list
    @content_tag_list ||= self.get_content_tag_list
  end
  
  
  def self.fetch_url_content(fetch_url)
    urlcontent = ''
    fetch_uri = URI.parse(fetch_url)
    if(fetch_uri.scheme.nil?)
      raise StandardError, "Fetch URL Content:  Invalid URL: #{fetch_url}"
    elsif(fetch_uri.scheme == 'http' or fetch_uri.scheme == 'https')  
      # TODO: need to set If-Modified-Since
      http = Net::HTTP.new(fetch_uri.host, fetch_uri.port) 
      http.read_timeout = 300
      response = fetch_uri.query.nil? ? http.get(fetch_uri.path) : http.get(fetch_uri.path + "?" + fetch_uri.query)
      case response
      # TODO: handle redirection?
      when Net::HTTPSuccess
        urlcontent = response.body
      else
        raise StandardError, "Fetch URL Content:  Fetch from #{fetch_url} failed: #{response.code}/#{response.message}"          
      end    
    else # unsupported URL scheme
      raise StandardError, "Fetch URL Content:  Unsupported scheme #{feed_url}"          
    end

    return urlcontent
  end
  
  def self.communitylist_url(communitytype = 'publishing')
    return "#{Settings.darmok_site}/api/data/communities?communitytype=#{communitytype}"
  end
  

  
end
