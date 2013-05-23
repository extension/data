# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class County < ActiveRecord::Base
  include CacheTools

  belongs_to :location

  def self.find_by_geoip(ipaddress,cache_options = {})
    cache_key = self.get_cache_key(__method__,{ipaddress: ipaddress})
    Rails.cache.fetch(cache_key,cache_options) do
      if(geoname = GeoName.find_by_geoip(ipaddress))
        if(location = Location.find_by_abbreviation(geoname.state_abbreviation))
          location.counties.where(name: geoname.county).first 
        else
          nil
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
      "#{state_fipsid}#{countycode}".to_i
    else
      "%02d" % state_fipsid + "#{countycode}"
    end
  end

    
end