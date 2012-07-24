#!/usr/bin/env ruby
require 'rubygems'
require 'thor'
require 'benchmark'

class GAImporter < Thor
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
              
    def associate_analytics_for_year_week(year,week)
      puts "Associating GA data to pages for #{year.to_s}-#{week.to_s}..." if options[:verbose]
      records = 0
      benchmark = Benchmark.measure do      
        records = Analytic.associate_with_pages_for_year_week(year,week)
      end
      UpdateTime.log("Analytic","associate_with_page_for_year_week",benchmark.real,{:year => year, :week => week, :records => records})
      puts "\t associated: #{records}" if options[:verbose]
    end
    
    def get_analytics_for_year_week(year,week)
      puts "Getting GA data for #{year.to_s}-#{week.to_s}..." if options[:verbose]
      records = 0
      benchmark = Benchmark.measure do      
        records = Analytic.import_analytics_for_year_week(year,week)
      end
      UpdateTime.log("Analytic","import_analytics_for_year_week",benchmark.real,{:year => year, :week => week, :records => records})
      puts "\t saved: #{records}" if options[:verbose]
    end
    
    def run_and_log(object,method,output)
      puts "Starting #{output}..." if options[:verbose]
      
      benchmark = Benchmark.measure do
        object.send(method)
      end
      UpdateTime.log(object.name,method,benchmark.real)
      
      puts "\t Finished #{output}" if options[:verbose]
    end
      
    def darmok_rebuilds    
      run_and_log(Page,'rebuild','darmok page import')
      run_and_log(Group,'rebuild','darmok group import')
      run_and_log(Tag,'rebuild','darmok tag import')
      run_and_log(PageTagging,'rebuild','darmok page tagging import')
      run_and_log(User,'rebuild','darmok user import')
    end
    
    def create_rebuilds
      run_and_log(Node,'rebuild','create node import')
      run_and_log(NodeGroup,'rebuild','create group node import')
      run_and_log(Revision,'rebuild','create revision import')
      run_and_log(AaeNode,'rebuild','create aae node import')
      run_and_log(NodeEvent,'rebuild','create node events import')
      run_and_log(NodeMetacontribution,'rebuild','create node contributors import')
    end
    
    def internal_rebuilds
      run_and_log(WeekStat,'mass_rebuild_from_analytics','week stat rebuild')
      run_and_log(PageTotal,'rebuild','page totals rebuild')
      run_and_log(PageDiff,'rebuild','page weekly differences rebuild')
      run_and_log(TotalDiff,'rebuild','total weekly differences rebuild')      
      run_and_log(Percentile,'rebuild','percentiles rebuild')      
   end
   
   def item_rebuild(model)
     if(model == 'WeekStat')
       method = 'mass_rebuild_from_analytics'
     else 
       method = 'rebuild'
     end
     object = Object.const_get(model)
     run_and_log(object,method,"#{model} #{method}")
   end
      
      
  end
  
  desc "analytics_for_year_week", "Import Google Analytics data for a specified date"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :year,:default => last_year_week[0], :desc => "Year to retrieve"
  method_option :week,:default => last_year_week[1], :desc => "Week to retrieve"
  method_option :associate,:default => true, :aliases => "-a", :desc => "Associate analytic with page (run Page.rebuild prior!)"
  def analytics_for_year_week
    load_rails(options[:environment])
    year = options[:year].to_i
    week = options[:week].to_i
    get_analytics_for_year_week(year,week)      
    if(options[:associate])
      associate_analytics_for_year_week(year,week)
    end
  end
  
  desc "analytics", "Import Google Analytics data for all year-weeks since last pulled"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :associate,:default => true, :aliases => "-a", :desc => "Associate analytic with page (run Page.rebuild prior!)"
  def analytics
    load_rails(options[:environment])
    
    latest_year_week = Analytic._latest_year_week
    if(latest_year_week.nil?)
      yearweeks = Analytic.all_year_weeks
    else
      next_year_week = Analytic.next_year_week(latest_year_week[0],latest_year_week[1])
      start_date = Analytic.date_pair_for_year_week(next_year_week[0],next_year_week[1])[0]
      end_date = (Date.today - 1)
      yearweeks = Analytic.year_weeks_between_dates(start_date,end_date)
    end
    

    yearweeks.each do |year,week|
      get_analytics_for_year_week(year,week)      
      if(options[:associate])
        associate_analytics_for_year_week(year,week)
      end
    end
  end
  
  desc "pages", "Rebuild/reimport pages from Darmok"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  def pages
    load_rails(options[:environment])
    puts "Starting darmok page import (no progress will be shown)..." if options[:verbose]
    Page.rebuild
    puts "\t Finished darmok page import" if options[:verbose]
  end
    
  desc "all_the_things", "Import data items from Darmok, Create, and GA"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  def all_the_things
    load_rails(options[:environment])
    darmok_rebuilds
    create_rebuilds
    
    # analytics
    latest_year_week = Analytic._latest_year_week
    if(latest_year_week.nil?)
      yearweeks = Analytic.all_year_weeks
    else
      next_year_week = Analytic.next_year_week(latest_year_week[0],latest_year_week[1])
      start_date = Analytic.date_pair_for_year_week(next_year_week[0],next_year_week[1])[0]
      end_date = (Date.today - 1)
      yearweeks = Analytic.year_weeks_between_dates(start_date,end_date)
    end
    
    yearweeks.each do |year,week|
      get_analytics_for_year_week(year,week)      
      associate_analytics_for_year_week(year,week)
    end

    # internal data
    internal_rebuilds
  end
  
  desc "darmok", "All Darmok Rebuilds"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  def darmok
    load_rails(options[:environment])
    darmok_rebuilds
  end
  
  desc "create", "All Create Rebuilds"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  def create
    load_rails(options[:environment])
    create_rebuilds
  end
  
  desc "internal", "All Internal Rebuilds"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  def internal
    load_rails(options[:environment])
    internal_rebuilds
  end
  
  desc "model", "Rebuild a specific model"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :name, :aliases => "-n", :desc => "Model name"
  def model
    load_rails(options[:environment])
    item_rebuild(options[:name])
  end
  
  
  
    
end

GAImporter.start
