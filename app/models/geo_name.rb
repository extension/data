# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class GeoName < ActiveRecord::Base
  geocoded_by :address, :latitude  => :lat, :longitude => :long


  def address
    [feature_name, state_abbrevation, 'US'].compact.join(', ')
  end


  def self.find_by_geoip(ipaddress)
    if(geoip_data = self.get_geoip_data(ipaddress))
      if(geoip_data[:country_code] == 'US')
        self.where("state_abbreviation = '#{geoip_data[:region]}'").where("feature_name = '#{geoip_data[:city]}'").near([geoip_data[:lat], geoip_data[:lon]],10).first
      else
        return nil
      end
    else
      return nil
    end
  end

  def self.get_geoip_data(ipaddress)
    if(geoip_data_file = Settings.geoip_data_file)
      if File.exists?(geoip_data_file)
        returnhash = {}
        if(data = GeoIP.new(geoip_data_file).city(ipaddress))
          returnhash[:country_code] = data[2]
          returnhash[:region] = data[6]
          returnhash[:city] = data[7]
          returnhash[:postal_code] = data[8]
          returnhash[:lat] = data[9]
          returnhash[:lon] = data[10]
          returnhash[:tz] = data[13]
          return returnhash
        end
      else
        return nil
      end
    else
      return nil
    end
  end

end