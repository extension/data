# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Location < ActiveRecord::Base
  include CacheTools


  UNKNOWN = 0
  STATE = 1
  INSULAR = 2
  OUTSIDEUS = 3
  
  has_many :counties
 
  scope :states, where(entrytype: STATE)


  def self.find_by_geoip(ipaddress,cache_options = {})
    cache_key = self.get_cache_key(__method__,{ipaddress: ipaddress})
    Rails.cache.fetch(cache_key,cache_options) do
      if(geoip_data = GeoName.get_geoip_data(ipaddress))
        if(geoip_data[:country_code] == 'US')
          self.find_by_abbreviation(geoip_data[:region])
        else
          self.find_by_abbreviation('OUTSIDEUS')
        end
      else
        nil
      end
    end
  end


  # the spec says leading 0 is required
  # but the R maps package leaves it as numeric, so I'm doing that
  def fips(make_integer = true)
    if(make_integer)
      fipsid
    else
      "%02d" % fipsid
    end
  end

end