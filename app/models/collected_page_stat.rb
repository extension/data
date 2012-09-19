# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class CollectedPageStat < ActiveRecord::Base
  extend YearWeek
  belongs_to :statable, polymorphic: true

  scope :overall, where(:group_id => 0)

  def self.rebuild
    self.connection.execute("TRUNCATE TABLE #{self.table_name};")
    self.rebuild_for_statable_metric({metric: 'unique_pageviews'})

    Group.launched.each do |group|
      self.rebuild_for_statable_metric({statable_object: group, metric: 'unique_pageviews'})
    end
  end

  def self.rebuild_for_statable_metric(options = {})
    statable_object = options[:statable_object]
    metric = options[:metric]
    return false if metric.nil?

    if(statable_object.nil?)
      statable_id = 0
      statable_type = 'Page'
      scope = Page
    else
      statable_id = statable_object.id
      statable_type = statable_object.class.name
      scope = statable_object.pages
    end

    datatypes = Page::DATATYPES
    datatypes.each do |datatype|
      insert_values = []
      stats = scope.by_datatype(datatype).stats_by_yearweek(metric,{force: true})
      stats.keys.sort.each do |yearweek|
        insert_list = []
        insert_list << statable_id
        insert_list << ActiveRecord::Base.quote_value(statable_type)
        insert_list << ActiveRecord::Base.quote_value(datatype)
        insert_list << ActiveRecord::Base.quote_value(metric)
        insert_list << yearweek
        (year,week) = self.yearweek_year_week(yearweek)
        insert_list << year
        insert_list << week
        insert_list << ActiveRecord::Base.quote_value(self.year_week_date(year,week))
        ['pages','seen','total','per_page','rolling','previous_week','previous_year','pct_change_week','pct_change_year'].each do |value|
          if(stats[yearweek][value].nil?)
            insert_list << 'NULL'
          else
            insert_list << stats[yearweek][value]
          end
        end
        insert_list << 'NOW()'
        insert_values << "(#{insert_list.join(',')})"
      end # yearweek loop
      if(!insert_values.blank?)
        columns = self.column_names.reject{|n| n == "id"}
        insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
        self.connection.execute(insert_sql)
      end
    end # datatype loop
    true
  end

  def self.max_for_metric(metric,nearest = nil)
    with_scope do
      max = where(metric: metric).maximum(:per_page)
      if(nearest)
        max = max + nearest - (max % nearest)
      end
    end
  end

  def self.panda_impacts(panda_comparison_weeks = 3, metric = 'unique_pageviews')
    panda_epoch_date = EpochDate.panda_epoch_date
    prior_panda_yearweeks = panda_epoch_date.previous_yearweeks(panda_comparison_weeks)
    post_panda_yearweeks =  panda_epoch_date.next_yearweeks(panda_comparison_weeks)

    post_panda_prior_yearweeks = []
    post_panda_year_weeks = panda_epoch_date.next_year_weeks(panda_comparison_weeks)
    post_panda_year_weeks.each do |year,week|
      post_panda_prior_yearweeks << EpochDate.yearweek(year-1,week)
    end

    scope = self.where(metric: metric).where(statable_type: 'Group').group("statable_id,datatype").select("statable_id as group_id,datatype,SUM(per_page) as sum_metric")

    prior_diffs = scope.where("yearweek IN (#{prior_panda_yearweeks.join(',')})")
    post_diffs = scope.where("yearweek IN (#{post_panda_yearweeks.join(',')})")
    post_diffs_prior_year = scope.where("yearweek IN (#{post_panda_prior_yearweeks.join(',')})")

    prior_views = {}
    prior_diffs.each do |pd|
      prior_views[pd.group_id] ||= {}
      prior_views[pd.group_id][pd.datatype] = (pd.sum_metric / panda_comparison_weeks)
    end

    post_views = {}
    post_diffs.each do |pd|
      post_views[pd.group_id] ||= {}
      post_views[pd.group_id][pd.datatype] = (pd.sum_metric / panda_comparison_weeks)
    end

    post_views_prior_year = {}
    post_diffs_prior_year.each do |pd|
      post_views_prior_year[pd.group_id] ||= {}
      post_views_prior_year[pd.group_id][pd.datatype] = (pd.sum_metric / panda_comparison_weeks)
    end


    views_change_by_group = {}
    post_views.each do |group_id,data|
      views_change_by_group[group_id] ||= {}

      Page::DATATYPES.each do |datatype|
        post_view_count =  (data[datatype].nil? ? nil : data[datatype])
        if(prior_views[group_id])
          prior_view_count =  (prior_views[group_id][datatype].nil? ? nil : prior_views[group_id][datatype])
        end

        if(post_views_prior_year[group_id])
          post_view_prior_year_count =  (post_views_prior_year[group_id][datatype].nil? ? nil : post_views_prior_year[group_id][datatype])
        end


        raw_change = 'n/a'
        pct_change = 'n/a'

        raw_change_year = 'n/a'
        pct_change_year = 'n/a'


        if((!prior_view_count.nil? and  (prior_view_count > 0)) and !post_view_count.nil?)
          raw_change = (post_view_count - prior_view_count)
          pct_change = raw_change / prior_view_count
        end

        if((!post_view_prior_year_count.nil? and  (post_view_prior_year_count > 0)) and !post_view_count.nil?)
          raw_change_year = (post_view_count - post_view_prior_year_count)
          pct_change_year = raw_change_year / post_view_prior_year_count
        end


        views_change_by_group[group_id][datatype] = {:raw_change => raw_change, :pct_change => pct_change, :raw_change_year => raw_change_year, :pct_change_year => pct_change_year}
      end
    end
    views_change_by_group
  end



end

