set :stages, %w(prod dev)
set :default_stage, "dev"
require 'capistrano/ext/multistage'
require 'capatross'
require "bundler/capistrano"
require './config/boot'
require "airbrake/capistrano"

set :application, "positronic"
set :repository,  "git@github.com:extension/positronic.git"
set :scm, "git"
set :user, "pacecar"
set :use_sudo, false
set :keep_releases, 3
ssh_options[:forward_agent] = true
set :port, 24
set :bundle_flags, '--deployment --binstubs'
set :rails_env, "production" #added for delayed job

before "deploy", "deploy:web:disable"
after "deploy:update_code", "deploy:link_and_copy_configs"
after "deploy:update_code", "deploy:cleanup"
after "deploy", "deploy:web:enable"

# relevant to positronic only, since it hasn't shifted
# to the non-web-disable deploy
after "deploy:web:disable",    "sidekiq:stop"
before "deploy:web:enable",   "sidekiq:start"

namespace :deploy do

  desc "Deploy the #{application} application with migrations"
  task :default, :roles => :app do

    # Invoke deployment with migrations
    deploy.migrations
  end

  # Override default restart task
  desc "Restart passenger"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  # bundle installation in the system-wide gemset
  desc "runs bundle update"
  task :bundle_install do
    run "cd #{release_path} && bundle install"
  end

  # Link up various configs (valid after an update code invocation)
  task :link_and_copy_configs, :roles => :app do
    run <<-CMD
    rm -rf #{release_path}/config/database.yml &&
    ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml &&
    ln -nfs #{shared_path}/config/settings.local.yml #{release_path}/config/settings.local.yml &&
    ln -nfs #{shared_path}/omniauth #{release_path}/tmp/omniauth &&
    ln -nfs #{shared_path}/downloads #{release_path}/tmp/downloads
    CMD
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

  # Override default web enable/disable tasks
  namespace :web do

    desc "Put Apache in maintenancemode by touching the maintenancemode file"
    task :disable, :roles => :app do
      invoke_command "touch /services/maintenance/#{vhost}.maintenancemode"
    end

    desc "Remove Apache from maintenancemode by removing the maintenancemode file"
    task :enable, :roles => :app do
      invoke_command "rm -f /services/maintenance/#{vhost}.maintenancemode"
    end

  end
end

namespace :sidekiq do
  desc 'Stop sidekiq'
  task 'stop', :roles => :app do
    # check status
    started = false
    invoke_command 'status workers' do |channel,stream,data|
      started = (data =~ %r{start})
    end
    if(started)
      invoke_command 'stop workers', via: 'sudo'
    end
  end

  desc 'Start sidekiq'
  task 'start', :roles => :app do
    stopped = false
    invoke_command 'status workers' do |channel,stream,data|
      stopped = (data =~ %r{stop})
    end
    if(stopped)
      invoke_command 'start workers', via: 'sudo'
    end
  end

  desc 'Restart sidekiq'
  task 'restart', :roles => :app do
    stop
    start
  end
end
