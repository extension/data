set :deploy_to, '/services/data/'
set :rails_env, 'production'
set :branch, "master"
set :vhost, 'data.extension.org'
server vhost, :app, :web, :db, :primary => true
