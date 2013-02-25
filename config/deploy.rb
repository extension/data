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
set :bundle_flags, ''
set :bundle_dir, ''
set :rails_env, "production" #added for delayed job

before "deploy", "deploy:web:disable"
after "deploy:update_code", "deploy:update_maint_msg"
after "deploy:update_code", "deploy:link_and_copy_configs"
after "deploy:update_code", "deploy:cleanup"
after "deploy", "deploy:web:enable"
# delayed job
after "deploy:stop",    "delayed_job:stop"
before "delayed_job:start", "delayed_job:reload"
after "deploy:start",   "delayed_job:start"

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

  desc "Update maintenance mode page/graphics (valid after an update code invocation)"
  task :update_maint_msg, :roles => :app do
     invoke_command "cp -f #{release_path}/public/maintenancemessage.html #{shared_path}/system/maintenancemessage.html"
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

    desc "Put Apache in maintenancemode by touching the system/maintenancemode file"
    task :disable, :roles => :app do
      invoke_command "touch #{shared_path}/system/maintenancemode"
    end

    desc "Remove Apache from maintenancemode by removing the system/maintenancemode file"
    task :enable, :roles => :app do
      invoke_command "rm -f #{shared_path}/system/maintenancemode"
    end

  end
end

namespace :delayed_job do
  desc "stops delayed_job"
  task :stop, :roles => :app do
    run "sudo god stop delayed_jobs"
  end
  
  desc "reloads delayed_job"
  task :reload, :roles => :app do
    run "sudo god load #{current_path}/config/delayed_job.god"
  end
  
  desc "starts delayed_job"
  task :start, :roles => :app do
    run "sudo god start delayed_jobs"
  end
end