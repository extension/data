# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ExperimentsController < ApplicationController
  before_filter :check_for_contributor, :check_for_group

  def index
  end

  def panda_impact_summary
    if(!params[:weeks].nil?)
      @panda_comparison_weeks =  params[:weeks].to_i
    else
      @panda_comparison_weeks = 3
    end
    @diffs = CollectedPageStat.panda_impacts(@panda_comparison_weeks)
  end

  def news_comparison
    @stats = YearWeekStatsComparator.new
    @stats['News'] = Page.news.stats_by_yearweek(@metric)
    @stats['Indexed News'] = Page.news.indexed.stats_by_yearweek(@metric)
  end

  def metric_comparisons
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype) and @datatype != 'All')
      # ToDo: error out
      @datatype = 'Article'
    end

    if(@contributor)
      if(params[:contributions] and params[:contributions] == 'meta')
        @contributions_type = 'Listed'
        scope = @contributor.unique_meta_contributed_pages.by_datatype(@datatype)
      else
        @contributions_type = 'Direct'
        scope = @contributor.unique_contributed_pages.by_datatype(@datatype)
      end
    elsif(@group)
      scope = @group.pages.by_datatype(@datatype)
    else
      scope = Page.by_datatype(@datatype)
    end

    @page_title_display = @page_title = "#{@datatype} Comparisons by Metric"
    @endpoint = @datatype.pluralize

    if(@contributor)
      @page_title += "- #{@contributions_type} Contributions - #{@contributor.fullname} (ID##{@contributor.id})"
      @page_title_display += "- #{@contributions_type} Contributions for #{@contributor.fullname}"
    elsif(@group)
      @page_title += " - Group ##{@group.id}"
      @page_title_display += " for #{@group.name}"
    end

    @stats = YearWeekStatsComparator.new
    PageStat::METRICS.each do |metric|
      @stats[metric] = scope.stats_by_yearweek(metric)
    end
  end

  def percentile_percentages
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype) and @datatype != 'All')
      # ToDo: error out
      @datatype = 'Article'
    end

    pagelist = Page.by_datatype(@datatype).with_totals_for_metric('unique_pageviews')
    @overall_count = pagelist.size
    @overall_total = pagelist.map(&:total).compact.sum
    @this_week_total = pagelist.map(&:this_week).compact.sum

    @totals_by_percentile = {}
    Settings.display_percentiles.each do |pct|
      @totals_by_percentile[pct] ||= {}
      pagelist = Page.by_datatype(@datatype).top_pages_by_percentile(pct)
      @totals_by_percentile[pct][:count] = pagelist.size
      @totals_by_percentile[pct][:overall] = pagelist.map(&:total).sum
      @totals_by_percentile[pct][:this_week] = pagelist.map(&:this_week).sum
    end
  end

  def weekly_overview_group
    @landing_stats = {}
    @home_stats = LandingStat.overall.stats_by_yearweek(@metric)
    Group.launched.order('name').each do |group|
      @landing_stats[group] = group.landing_stats.stats_by_yearweek(@metric)
    end

    @page_stats = {}
    @group_page_stats = {}
    Page::DATATYPES.each do |datatype|
      @page_stats[datatype] ||= {}
      @page_stats[datatype]['mean'] = CollectedPageStat.overall.by_metric(@metric).by_datatype(datatype).average('per_page')
      @page_stats[datatype]['this_week'] = CollectedPageStat.overall.by_metric(@metric).by_datatype(datatype).latest_week.pluck('per_page').first
      @page_stats[datatype]['pct_99'] = CollectedPageStat.overall.by_metric(@metric).by_datatype(datatype).latest_week.pluck('pct_99').first

      Group.launched.order('name').each do |group|
        @group_page_stats[group] ||= {}
        @group_page_stats[group][datatype] ||= {}
        @group_page_stats[group][datatype]['mean'] = group.collected_page_stats.by_metric(@metric).by_datatype(datatype).average('per_page')
        @group_page_stats[group][datatype]['this_week'] = group.collected_page_stats.by_metric(@metric).by_datatype(datatype).latest_week.pluck('per_page').first
        @group_page_stats[group][datatype]['pct_99'] = group.collected_page_stats.by_metric(@metric).by_datatype(datatype).latest_week.pluck('pct_99').first
      end
    end
  end

  def weekly_group_graph
    @groupcount = params[:groupcount] || 10
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype) and @datatype != 'All')
      # ToDo: error out
      @datatype = 'Article'
    end

    @groups_list = Group.top_by_page_average.all
    @groups_of = (@groups_list.size  / @groupcount).ceil

    @statgroups = []
    @all_stats = Page.by_datatype(@datatype).stats_by_yearweek(@metric)
    @groups_list.in_groups_of(@groups_of,false).each do |grouplist|
      stats = YearWeekStatsComparator.new
      stats['all'] = @all_stats
      grouplist.each do |group|
        group_stats =  group.pages.by_datatype(@datatype).stats_by_yearweek(@metric)
        if(!group_stats.blank?)
          stats[group.name] = group_stats
        end
      end
      @statgroups << stats
    end
  end


  protected

  def check_for_group
    if(params[:group_id])
      @group = Group.find(params[:group_id])
    end
    true
  end

  def check_for_contributor
    if(params[:contributor_id])
      @contributor = Contributor.find_by_id(params[:contributor_id])
    end
    true
  end


end