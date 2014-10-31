source 'https://rubygems.org'
source 'https://engineering.extension.org/rubygems'

gem 'rails', '3.2.20'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# data
gem 'mysql2'

# Gems used only for assets and not required
# in production environments by default.
# speed up sppppppprooooockets
gem 'turbo-sprockets-rails3'
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
  # files for bootstrap-in-asset-pipeline integration
  gem 'anjlab-bootstrap-rails', '~> 2.0', :require => 'bootstrap-rails'
  gem 'jquery-ui-rails'
  gem 'jquery-migrate-rails'
  gem 'jquery-tablesorter'
end

# server settings
gem "rails_config"

# authentication
gem 'omniauth', "~> 1.0"
gem 'omniauth-openid'

# jquery magick
gem 'jquery-rails'

# pagination
gem 'kaminari'

# background jobs
gem 'sidekiq'

# google analytics retrieval
gem "garb" # garb for now until it breaks June 2012

# command line tools
gem 'thor'

# campfire integration
#gem "tinder", "~> 1.8.0"

# legacy data support
gem 'safe_attributes'

# jqplot
gem 'outfielding-jqplot-rails'

# exception handling
gem 'honeybadger'

# caching
gem 'redis-rails'

# useragent analysis
gem 'useragent'

# ip to geo mapping
gem 'geocoder'
gem 'geoip'

group :development do
  # require the powder gem
  gem 'powder'
  gem 'net-http-spy'
  gem 'pry'
  gem 'capistrano', '~> 2.15.5'
  gem 'capatross'

  # moar advanced stats in dev only
  #gem 'gsl', :git => 'git://github.com/30robots/rb-gsl.git'
  #gem 'statsample-optimization', :require => 'statsample'

  gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'

end
