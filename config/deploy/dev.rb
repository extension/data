set :rails_env, 'production'
set :branch, "development"
set :deploy_to, '/services/data/'
server 'dev.data.extension.org', :app, :web, :db, :primary => true
