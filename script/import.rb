#!/usr/bin/env ruby
require 'rubygems'
require 'thor'
require 'benchmark'

class GAImporter < Thor
  include Thor::Actions
  
  # these are not the tasks that you seek
  no_tasks do
    # load rails based on environment
    
    def load_rails(environment)
      if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
        ENV["RAILS_ENV"] = environment
      end
      require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
    end
        
    def associate_analytics_for_date(date)
      benchmark = Benchmark.measure do      
        Analytic.bydate(date).each do |analytic|
          puts "Setting page data for analytic #{analytic.id} ..." if options[:verbose]
          analytic.associate_with_page
        end
      end
      UpdateTime.log("AnalyticAssociate",benchmark.real,{:operation => 'associate',:date => date})
    end
    
    def get_analytics_for_date(date)
      puts "Getting GA data for #{date.to_s}-..." if options[:verbose]
      records = 0
      benchmark = Benchmark.measure do      
        records = Analytic.import_analytics({:segment => 'all', :date => date})
      end
      UpdateTime.log("AnalyticImport",benchmark.real,{:operation => 'import',:date => date, :records => records})
      puts "\t saved: #{records}" if options[:verbose]
    end
    
    def run_and_log(object,method,output)
      puts "Starting #{output}..." if options[:verbose]
      
      benchmark = Benchmark.measure do
        object.send(method)
      end
      UpdateTime.log(object.name,benchmark.real)
      
      puts "\t Finished #{output}" if options[:verbose]
    end
      
    def darmok_rebuilds    
      run_and_log(Page,'rebuild','darmok page import')
      run_and_log(Group,'rebuild','darmok group import')
      run_and_log(User,'rebuild','darmok user import')
    end
    
    def create_rebuilds
      run_and_log(Node,'rebuild','create node import')
      run_and_log(NodeGroup,'rebuild','create group node import')
      run_and_log(Revision,'rebuild','create revision import')
      run_and_log(AaeNode,'rebuild','create aae node import')
      run_and_log(WorkflowEvent,'rebuild','create workflow import')
    end
    
    def internal_rebuilds
      run_and_log(WeekStat,'mass_rebuild_from_analytics','week stat rebuild')
      run_and_log(PageTotal,'rebuild','page totals rebuild')
      run_and_log(TotalDiff,'rebuild_all','week upv totals rebuild')      
   end
      
      
  end
  
  desc "analytics_for_date", "Import Google Analytics data for a specified date"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :date,:default => (Date.today - 1).to_s, :desc => "Date to retrieve"
  method_option :associate,:default => true, :aliases => "-a", :desc => "Associate analytic with page (run rebuild prior!)"
  def analytics_for_date
    load_rails(options[:environment])
    date = Date.parse(options[:date])
    get_analytics_for_date(date)
    if(options[:associate])
      associate_analytics_for_date(date)
    end
  end
  
  desc "analytics", "Import Google Analytics data for all dates since last pulled"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :associate,:default => true, :aliases => "-a", :desc => "Associate analytic with page (run rebuild prior!)"
  def analytics
    load_rails(options[:environment])
    start_date = Analytic.latest_date + 1
    end_date = (Date.today - 1)
    start_date.upto(end_date) do |date|
      get_analytics_for_date(date)      
      if(options[:associate])
        associate_analytics_for_date(date)
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
    start_date = Analytic.latest_date + 1
    end_date = (Date.today - 1)
    start_date.upto(end_date) do |date|
      get_analytics_for_date(date)      
      associate_analytics_for_date(date)
    end
    
    # internal data
    internal_rebuilds
  end
  
    
end

GAImporter.start
