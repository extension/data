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
    
    def get_segment_data_for_date(segment,date)
      RawAnalytic.import_analytics({:segment => segment, :date => date})
    end
    
    
  end
  
  desc "import", "Import Google Analytics data by date"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :date,:default => (Date.today - 1).to_s, :desc => "Date to retrieve"
  method_option :segments,:default => 'all', :desc => "Segments (e.g. 'all','googlesearch','us_googlesearch')"
  def import
    load_rails(options[:environment])
    date = Date.parse(options[:date])
    segments = options[:segments].split(%r{\s*,\s*})
    segments.each do |segment|
      puts "Getting GA data for segment #{segment} for #{date.to_s}-..." if options[:verbose]
      records = RawAnalytic.import_analytics({:segment => segment, :date => date})
      puts "\t saved: #{records}" if options[:verbose]
    end
  end
  
  desc "import_all_the_things", "Import Google Analytics data by date"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Show progress"
  method_option :start_date,:default => '2007-02-23', :desc => "start date"
  method_option :end_date,:default => (Date.today - 1).to_s, :desc => "end date"
  method_option :segments,:default => 'all', :desc => "Segments (e.g. 'all','googlesearch','us_googlesearch')"
  def import_all_the_things
    load_rails(options[:environment])
    start_date = Date.parse(options[:start_date])
    end_date = Date.parse(options[:end_date])
    segments = options[:segments].split(%r{\s*,\s*})
    start_date.upto(end_date) do |date|
      segments.each do |segment|
        puts "Getting GA data for segment #{segment} for #{date.to_s}-..." if options[:verbose]
        records = RawAnalytic.import_analytics({:segment => segment, :date => date})
        puts "\t saved: #{records}" if options[:verbose]
      end
    end
  end
end

GAImporter.start
