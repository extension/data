#!/usr/bin/env ruby
require 'rubygems'
require 'thor'
require 'faster_csv'

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
      Analytic.bydate(date).each do |analytic|
        puts "Setting page data for analytic #{analytic.id} ..." if options[:verbose]
        analytic.associate_with_page
      end
    end
    
    def get_analytics_for_date(date)
      puts "Getting GA data for #{date.to_s}-..." if options[:verbose]
      records = Analytic.import_analytics({:segment => 'all', :date => date})
      puts "\t saved: #{records}" if options[:verbose]
    end
    
    def darmok_rebuilds
      puts "Starting darmok page import (no progress will be shown)..." if options[:verbose]
      Page.rebuild
      puts "\t Finished darmok page import (no progress will be shown)..." if options[:verbose]
   
      puts "Starting darmok group import (no progress will be shown)..." if options[:verbose]
      Group.rebuild
      puts "\t Finished darmok group import (no progress will be shown)..." if options[:verbose]
    
      puts "Starting darmok user import (no progress will be shown)..." if options[:verbose]
      User.rebuild
      puts "\t Finished darmok user import (no progress will be shown)..." if options[:verbose]
    end
    
    def create_rebuilds
      puts "Starting create node import (no progress will be shown)..." if options[:verbose]
      Node.rebuild
      puts "\t Finished create node import (no progress will be shown)..." if options[:verbose]
    
      puts "Starting create group node import (no progress will be shown)..." if options[:verbose]
      NodeGroup.rebuild
      puts "\t Finished create group node import (no progress will be shown)..." if options[:verbose]
    
      puts "Starting create revision import (no progress will be shown)..." if options[:verbose]
      Revision.rebuild
      puts "\t Finished create revision import (no progress will be shown)..." if options[:verbose]
    
      puts "Starting create aae node import (no progress will be shown)..." if options[:verbose]
      AaeNode.rebuild
      puts "\t Finished create aae node import (no progress will be shown)..." if options[:verbose]
    
      puts "Starting create workflow import (no progress will be shown)..." if options[:verbose]
      WorkflowEvent.rebuild
      puts "\t Finished create workflow import (no progress will be shown)..." if options[:verbose] 
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
    puts "\t Finished darmok page import (no progress will be shown)..." if options[:verbose]
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
  end
  
    
end

GAImporter.start
