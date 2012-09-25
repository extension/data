#!/usr/bin/env ruby
require 'rubygems'
require 'thor'
require 'benchmark'

class DataImporter < Thor
  include Thor::Actions

  def self.year_week_for_date(date)
    [date.cwyear,date.cweek]
  end

  def self.last_year_week
    last_week_date = Date.today - 7
    self.year_week_for_date(last_week_date)
  end


  # these are not the tasks that you seek
  no_tasks do
    # load rails based on environment

    def load_rails(environment)
      if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
        ENV["RAILS_ENV"] = environment
      end
      require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
    end


    def run_and_log(rebuilder,model,action)
      puts "Starting #{model}##{action}..." if options[:verbose]
      run_time = rebuilder.run_and_log(model,action)
      puts "\t Finished #{model}##{action} (#{run_time.round(2)}s)" if options[:verbose]
    end

    def rebuild_group(group)
      rebuilder = Rebuild.start(group)
      rebuilder.list_of_rebuilds.each do |(model,action)|
        run_and_log(rebuilder,model,action)
      end
      rebuilder.finish
    end

    def internal_rebuilds
      Rails.cache.clear
    end


    def rebuild_single(model,method='rebuild')
      rebuilder = Rebuild.start(group)
      run_and_log(rebuilder,model,action)
      rebuilder.finish
    end
  end


  desc "analytics", "Import Google Analytics data for all year-weeks since last pulled"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :associate,:default => true, :aliases => "-a", :desc => "Associate analytic with page (run Page.rebuild prior!)"
  def analytics
    load_rails(options[:environment])
    rebuild_group('analytics')
  end

  desc "all_the_things", "Import data items from Darmok, Create, and GA"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  def all_the_things
    load_rails(options[:environment])
    Rails.cache.clear
    rebuild_group('all')
  end

  desc "weekly", "Weekly import of data from Darmok, Create, GA, and Internal Stat Rebuilds"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  def weekly
    # currently equivalent to "all_the_things"
    load_rails(options[:environment])
    Rails.cache.clear
    rebuild_group('all')
  end

  desc "darmok", "All Darmok Rebuilds"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  def darmok
    load_rails(options[:environment])
    rebuild_group('darmok')
  end

  desc "create", "All Create Rebuilds"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  def create
    load_rails(options[:environment])
    rebuild_group('create')
  end

  desc "internal", "All Internal Rebuilds"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  def internal
    load_rails(options[:environment])
    Rails.cache.clear
    rebuild_group('internal')
  end

  desc "model", "Rebuild a specific model"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :name, :aliases => "-n", :desc => "Model name", required: true
  method_option :method, :aliases => "-m", default: 'rebuild', :desc => "Model method"
  def model
    load_rails(options[:environment])
    rebuild_single(options[:name],options[:method])
  end

end

DataImporter.start
