# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Group < ActiveRecord::Base
  extend YearWeek
  has_many :node_groups
  has_many :nodes, :through => :node_groups
  has_many :node_activities, :through => :nodes
  has_many :tags
  has_many :pages, :through => :tags
  has_many :analytics, :through => :tags
  has_many :page_stats, :through => :tags
  has_many :landing_stats
  has_many :node_activity_diffs

  has_many :contributor_groups
  has_many :contributors, through: :contributor_groups


  scope :launched, where(:is_launched => true)

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    insert_values = []
    DarmokCommunity.where("drupal_node_id IS NOT NULL").each do |group|
      insert_list = []
      insert_list << group.id
      insert_list << group.drupal_node_id
      insert_list << ActiveRecord::Base.quote_value(group.name)
      insert_list << group.is_launched
      insert_list << ActiveRecord::Base.quote_value(group.created_at.to_s(:db))
      insert_list << ActiveRecord::Base.quote_value(group.updated_at.to_s(:db))
      insert_values << "(#{insert_list.join(',')})"
    end
    insert_sql = "INSERT INTO #{self.table_name} VALUES #{insert_values.join(',')};"
    self.connection.execute(insert_sql)
  end

  def self.top_or_bottom_by_views(top_or_bottom,options = {})
    case top_or_bottom
    when 'top'
      sortorder = 'total_diffs.views DESC'
    when 'bottom'
      sortorder = 'total_diffs.views ASC,total_diffs.pages DESC'
    else
      sortorder = 'total_diffs.views ASC,total_diffs.pages DESC'
    end
    yearweek = options[:yearweek] || Analytic.latest_yearweek
    pagecount = options[:pagecount] || 10
    limit = options[:limit] || 5
    datatype = options[:datatype] || 'Article'
    with_scope do
      joins(:total_diffs).where("total_diffs.datatype = ?",datatype).where("total_diffs.yearweek = ?",yearweek).where("total_diffs.pages >= ?",pagecount).order(sortorder).limit(limit)
    end
  end

  def self.top_views(options = {})
    self.top_or_bottom_by_views('top',options)
  end

  def self.bottom_views(options = {})
    self.top_or_bottom_by_views('bottom',options)
  end



end