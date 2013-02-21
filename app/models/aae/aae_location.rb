# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AaeLocation < ActiveRecord::Base
  # connects to the aae database
  self.establish_connection :aae
  self.table_name='locations'

  include CacheTools

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

end

