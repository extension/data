set :branch, "master"
set :deploy_to, '/services/data/'
server 'data.extension.org', :app, :web, :db, :primary => true
