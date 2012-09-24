# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Node < ActiveRecord::Base
  extend CacheTools
  extend YearWeek
  has_one :page
  has_many :node_groups
  has_many :groups, :through => :node_groups
  has_many :aae_nodes
  has_many :node_activities
  has_many :node_metacontributions
  has_many :meta_contributors, :through => :node_metacontributions, :source => :contributor
  has_many :activity_contributors, :through => :node_activities, :source => :contributor

  # datatypes that we care about
  PUBLISHED_TYPES = ['article','faq','news']

  scope :by_datatype, lambda{|datatype|
    case datatype
    when 'all'
      where(1)
    else
      where("node_type = ?",datatype)
    end
  }

  # used as a sanitycheck list
  NODE_SCOPES = ['all_nodes','articles','faqs','news','publishables','nonpublishables','forums']

  scope :all_nodes, where(1) # just a convenience scope for scoping node types and activity types
  scope :articles, where(node_type: 'article')
  scope :faqs,     where(node_type: 'faq')
  scope :news,     where(node_type: 'news')
  scope :forums,   where(node_type: 'forum')
  scope :publishables, where("node_type IN (#{PUBLISHED_TYPES.collect{|type| quote_value(type)}.join(', ')})")
  scope :nonpublishables, where("node_type NOT IN (#{PUBLISHED_TYPES.collect{|type| quote_value(type)}.join(', ')})")

  scope :has_page, where(:has_page => true)
  scope :created_since, lambda {|date| where("#{self.table_name}.created_at >= ?",date).order("#{self.table_name}.created_at")}

  scope :latest_activity, lambda{
    yearweek = Analytic.latest_yearweek
    joins(:node_activities).where("YEARWEEK(node_activities.created_at,3) = ?",yearweek)
  }

  def display_title(options = {})
    truncate_it = options[:truncate].nil? ? true : options[:truncate]

    if(self.title.blank?)
      display_title = '(blank)'
    elsif(truncate_it)
      display_title = self.title.truncate(80, :separator => ' ')
    else
      display_title = self.title
    end
    display_title
  end

  def contributions_by_contributor
    self.activity_contributors.group("contributors.id").select("contributors.*, group_concat(node_activities.event) as contributions")
  end

  def meta_contributions_by_contributor
    self.meta_contributors.group("contributors.id").select("contributors.*, group_concat(node_metacontributions.role) as metacontributions")
  end

  def contributions_count
    counts = {}
    counts[:contributors] = self.node_activities.count('contributor_id',:distinct => true)
    counts[:actions] = self.node_activities.count
    counts[:byaction] = self.node_activities.group('event').count
    counts
  end

  def metacontributions_count
    counts = {}
    counts[:contributors] = self.node_metacontributions.count('contributor_id',:distinct => true)
    counts[:actions] = self.node_metacontributions.count
    counts[:byaction] = self.node_metacontributions.group('role').count
    counts
  end

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    CreateNode.find_in_batches do |group|
      insert_values = []
      group.each do |node|
        insert_list = []
        insert_list << node.nid
        insert_list << node.vid
        insert_list << ActiveRecord::Base.quote_value(node.type)
        insert_list << ActiveRecord::Base.quote_value(node.title)
        insert_list << ActiveRecord::Base.quote_value(node.created_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(node.updated_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (id,revision_id,node_type,title,created_at,updated_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end

    # set page flag
    update_sql = "UPDATE #{self.table_name},#{Page.table_name} SET #{self.table_name}.has_page = 1 WHERE #{self.table_name}.id = #{Page.table_name}.node_id and #{Page.table_name}.source = 'create'"
    self.connection.execute(update_sql)

  end

  def self.counts_by_yearweek
    with_scope do
      self.group("YEARWEEK(#{self.table_name}.created_at,3)").count
    end
  end

  def self.published_since(date)
    joins(:node_activities).where("node_activities.event = #{NodeActivity::PUBLISHED}").where("node_activities.created_at > ?",date).select("distinct(#{self.table_name}.id),#{self.table_name}.*")
  end

  def self.earliest_created_at
    with_scope do
      self.minimum(:created_at)
    end
  end

  def self.overall_stats(activity,cache_options = {})
    cache_key = self.get_cache_key(__method__,{activity: activity, scope_sql: current_scope ? current_scope.to_sql : ''})
    Rails.cache.fetch(cache_key,cache_options) do
      stats = {}
      with_scope do
        eca = self.earliest_created_at
        if(eca.blank?)
          return stats
        end

        contributors_count =  "COUNT(DISTINCT(node_activities.contributor_id)) as contributors"
        contributions_count =  "COUNT(node_activities.id) as contributions"
        items_count = "COUNT(DISTINCT(node_activities.node_id)) as items"

        scope = self.joins(:node_activities)
        if(activity != NodeActivity::ALL_ACTIVITY)
          scope = scope.where('node_activities.activity = ?',activity)
        end
        result = scope.select("#{contributions_count}, #{contributors_count}, #{items_count}").first
        stats = {contributions: result.contributions, contributors: result.contributors, items: result.items}
      end
      stats
    end
  end

  def stats_by_yearweek(activity,cache_options = {})
    self.class.where(id: self.id).stats_by_yearweek(activity,cache_options = {})
  end

  def self.stats_by_yearweek(activity,cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__,{activity: activity, scope_sql: current_scope ? current_scope.to_sql : ''})
      Rails.cache.fetch(cache_key,cache_options) do
        with_scope do
          _stats_by_yearweek(activity,cache_options)
        end
      end
    else
      with_scope do
        _stats_by_yearweek(activity,cache_options)
      end
    end
  end

  def self._stats_by_yearweek(activity,cache_options = {})
    stats = YearWeekStats.new
    cache_key = self.get_cache_key(__method__,{activity: activity, scope_sql: current_scope ? current_scope.to_sql : ''})
    with_scope do
      yearweek_condition = "YEARWEEK(node_activities.created_at,3)"
      contributors_count =  "COUNT(DISTINCT(node_activities.contributor_id)) as contributors"
      contributions_count =  "COUNT(node_activities.id) as contributions"
      items_count = "COUNT(DISTINCT(node_activities.node_id)) as items"

      scope = self.joins(:node_activities).group(yearweek_condition)
      if(activity != NodeActivity::ALL_ACTIVITY)
        scope = scope.where('node_activities.activity = ?',activity)
      end
      week_stats_query = scope.select("#{yearweek_condition} as yearweek, #{contributions_count}, #{contributors_count}, #{items_count}")

      weekstats_by_yearweek = {}
      week_stats_query.each do |ws|
        weekstats_by_yearweek[ws.yearweek] = {contributions: ws.contributions, contributors: ws.contributors, items: ws.items}
      end

      self.eligible_year_weeks.each do |year,week|
        yearweek = self.yearweek(year,week)
        if(weekstats_by_yearweek[yearweek])
          stats[yearweek] = weekstats_by_yearweek[yearweek]
        else
          stats[yearweek] = {contributions: 0, contributors: 0, items: 0}
        end
      end
    end
    stats
  end

  def self.published_workflow_stats_since_migration
    published_workflow_stats_since_date(EpochDate::CREATE_FINAL_WIKI_MIGRATION)
  end

  def self.published_workflow_stats_since_date(date,rawnodecounts=false)
    nodelist = []
    with_scope do
      nodelist = self.published_since(date)
    end
    nodecounts = {}
    nodelist.each do |node|
      published_count = 0
      reviewed_counts = []
      reviews = 0
      node.node_activities.created_since(date).each do |wfe|
        if(wfe.event == NodeActivity::PUBLISHED)
          published_count += 1
          reviewed_counts << reviews
          reviews = 0
        elsif(wfe.is_reviewed_event?)
          reviews += 1
        end
      end
      nodecounts[node.id] = {:published => published_count, :reviewed => reviewed_counts.select{|i| i> 0}.size}
    end
    if(rawnodecounts)
      nodecounts
    else
      stats = {:total => 0, :reviewed => 0, :publish_count => 0, :review_count => 0}
      nodecounts.each do |node_id,counts|
        stats[:total] += 1
        stats[:reviewed] += 1 if counts[:reviewed] > 0
        stats[:publish_count] += counts[:published]
        stats[:review_count] += counts[:reviewed]
      end
      stats
    end
  end

  def self.earliest_year_week
    if(@yearweek.blank?)
      earliest_date = self.minimum(:created_at).to_date
      @yearweek = [earliest_date.cwyear,earliest_date.cweek]
    end
    @yearweek
  end

  def self.eligible_year_weeks
    latest_date = Analytic.latest_date
    with_scope do
      # scoped start date
      earliest_created_at = self.minimum(:created_at)
      if(!earliest_created_at.nil?)
        start_date = earliest_created_at.to_date
        self.year_weeks_between_dates(start_date,latest_date)
      else
        []
      end
    end
  end

  def self.rebuild_activity_cache(do_groups = true)

    NODE_SCOPES.each do |node_scope|
      NodeActivity::ACTIVITIES.each do |activity|
        self.send(node_scope).overall_stats(activity,{force: true})
        self.send(node_scope).stats_by_yearweek(activity,{force: true})
      end
    end

    if(do_groups)
      Group.launched.each do |group|
        NODE_SCOPES.each do |node_scope|
          NodeActivity::ACTIVITIES.each do |activity|
            group.nodes.send(node_scope).overall_stats(activity,{force: true})
            group.nodes.send(node_scope).stats_by_yearweek(activity,{force: true})
          end
        end
      end
    end

  end


end