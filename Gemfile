source 'https://rubygems.org'
source 'http://systems.extension.org/rubygems/'

gem 'rails', '3.2.8'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# data
gem 'mysql2'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
  # files for bootstrap-in-asset-pipeline integration
  gem 'anjlab-bootstrap-rails', '>= 2.0', :require => 'bootstrap-rails'
  gem 'jquery-ui-rails'
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

# Deploy with Capistrano
gem 'capistrano'
gem 'capatross'

# background jobs
gem 'delayed_job_active_record'
gem 'daemons'

# google analytics retrieval
gem "garb" # garb for now until it breaks June 2012

# command line tools
gem 'thor'

# campfire integration
#gem "tinder", "~> 1.8.0"

# legacy data support
gem 'safe_attributes'

# google visualization api integration
gem "google_visualr", ">= 2.1"

# jqplot
gem 'jqplot-rails', :git => 'git://github.com/extension/jqplot-rails.git'

# exception handling
gem 'airbrake'

# memcached
gem 'dalli'

group :development do
  # require the powder gem
  gem 'powder'
  gem 'net-http-spy'
  gem 'pry'

  # moar advanced stats in dev only
  #gem 'gsl', :git => 'git://github.com/30robots/rb-gsl.git'
  #gem 'statsample-optimization', :require => 'statsample'

  # footnotes
  gem 'rails-footnotes', '>= 3.7.5.rc4', :group => :development
  gem 'quiet_assets'
end
