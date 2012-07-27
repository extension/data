# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class NodeWeekTotal < ActiveRecord::Base
  belongs_to :group
  extend YearWeek
  
  
  scope :by_year_week, lambda {|year,week| where(:year => year).where(:week => week) }
  scope :by_datatype, lambda{|datatype| where(:datatype => datatype)}
  scope :by_event_type, lambda{|event_type| where(:event_type => event_type)}
  scope :overall, where(:group_id => 0)


  def self.rebuild
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    self.rebuild_by_data_and_event_type
    Group.launched.each do |group|
      self.rebuild_by_data_and_event_type(:group => group)
    end
  end
  
  def self.rebuild_by_data_and_event_type(options = {})
    group = options[:group]
    if(group.nil?)
      group_id = 0
    else
      group_id = group.id
    end
    
    event_types = ['all','edits'] # all we care about for now
    datatypes = ['all'] + Node::PUBLISHED_DATATYPES
    insert_values = []

    datatypes.each do |datatype|
      year_weeks = ((group.nil?) ? NodeEvent.by_datatype(datatype).eligible_year_weeks : group.node_events.by_datatype(datatype).eligible_year_weeks)
      nodecounts = ((group.nil?) ? Node.by_datatype(datatype).counts_by_yearweek : group.nodes.by_datatype(datatype).counts_by_yearweek)

      event_types.each do |event_type|
        by_yearweek_stats = ((group.nil?) ? NodeEvent.by_datatype(datatype).stats_by_yearweek(event_type) : group.node_events.by_datatype(datatype).stats_by_yearweek(event_type))
        year_weeks.each do |year,week|
          current_key_string = self.yearweek(year,week)
          nodecount = nodecounts.select{|yearweek,count| yearweek <= self.yearweek(year,week)}.values.sum
          total = (by_yearweek_stats[current_key_string].nil? ? 0 : by_yearweek_stats[current_key_string][:total])                     
          items = (by_yearweek_stats[current_key_string].nil? ? 0 : by_yearweek_stats[current_key_string][:items])
          users = (by_yearweek_stats[current_key_string].nil? ? 0 : by_yearweek_stats[current_key_string][:users])
          insert_list = []
          insert_list << group_id
          insert_list << ActiveRecord::Base.quote_value(datatype)
          insert_list << ActiveRecord::Base.quote_value(event_type)
          insert_list << self.yearweek(year,week)
          insert_list << year
          insert_list << week
          insert_list << ActiveRecord::Base.quote_value(self.yearweek_date(year,week))
          insert_list << nodecount
          insert_list << total        
          insert_list << items
          insert_list << users
          insert_list << 'NOW()'        
          insert_values << "(#{insert_list.join(',')})"
        end # year-week
      end # event_types
    end # datatypes    

    if(!insert_values.blank?)
      columns = self.column_names.reject{|n| n == "id"}
      insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end      
  end


  def self.graph_data(column_value,showrolling = true)
    returndata = []
    value_data = []
    rolling_data = []
    with_scope do
      running_total = 0 
      weekcount = 0
      self.order(:yearweek_date).each do |nwt|
        weekcount += 1
        value = nwt.send(column_value)
        running_total += value
        rolling_data << [nwt.yearweek_date,(running_total / weekcount)]
        value_data << [nwt.yearweek_date,value]
      end
    end
    if(showrolling)
      returndata = [value_data,rolling_data]
    else
      returndata = [value_data]
    end
    returndata
  end

  def self.graph_max(column_value,percentile)
    with_scope do 
      self.pluck(column_value).nist_percentile(percentile)
    end
  end
  

 end