set :branch, "development"
set :deploy_to, '/services/data/'
server 'demo.data.extension.org', :app, :web, :db, :primary => true
