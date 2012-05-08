source 'https://rubygems.org'
source 'http://systems.extension.org/rubygems/'

gem 'rails', '~> 3.2.3'

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
#gem 'capatross'

# background jobs
gem 'delayed_job_active_record'
gem 'daemons'

# google analytics retrieval
gem 'garb'

# command line tools
gem 'thor'

# csv output/import
gem 'fastercsv'

# campfire integration
gem "tinder", "~> 1.8.0"

group :development do
  # require the powder gem
  gem 'powder'
  gem 'net-http-spy'
end