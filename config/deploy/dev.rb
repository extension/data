set :rails_env, 'production'
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'master'
end
set :deploy_to, '/services/data/'
server 'dev-data.extension.org', :app, :web, :db, :primary => true
