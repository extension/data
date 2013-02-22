# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AaeCounty < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :aae
  self.table_name='counties'

  include CacheTools


  belongs_to :location, class_name: 'AaeLocation'

  def self.find_by_geoip(ipaddress,cache_options = {})
    cache_key = self.get_cache_key(__method__,{ipaddress: ipaddress})
    Rails.cache.fetch(cache_key,cache_options) do
      if(geoname = GeoName.find_by_geoip(ipaddress))
        if(location = AaeLocation.find_by_abbreviation(geoname.state_abbreviation))
          location.counties.where(name: geoname.county).first 
        else
          nil
        end
      else
        nil
      end
    end
  end
  
end

