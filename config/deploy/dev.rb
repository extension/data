set :deploy_to, '/services/data/'
set :rails_env, 'production'
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'master'
end
set :vhost, 'dev-data.extension.org'
server vhost, :app, :web, :db, :primary => true
