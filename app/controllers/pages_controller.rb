# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class PagesController < ApplicationController
  before_filter :check_for_group

  def index
    @landing_stats = LandingStat.overall.stats_by_yearweek(@metric)
    @datatype_stats = YearWeekStatsComparator.new
    Page::DATATYPES.each do |datatype|
      @datatype_stats[datatype] = Page.by_datatype(datatype).stats_by_yearweek(@metric)
    end
  end

  def show
    @page = Page.includes(:node).find(params[:id])
  end

  def details
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      # ToDo: error out
      @datatype = 'Article'
    end

    @stats = Page.by_datatype(@datatype).stats_by_yearweek(@metric)
    @percentiles = Page.by_datatype(@datatype).percentiles_by_yearweek(@metric)
  end


  def totals
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      # for now, error later
      @datatype = 'Article'
    end

    # todo: contributor, tags
    if(@group)
      scope = @group.pages.by_datatype(@datatype)
    else
      scope = Page.by_datatype(@datatype)
    end

    # order_by
    if(params[:order_by] and Page.totals_list_columns.include?(params[:order_by]))
      @order_by = params[:order_by]
    else
      @order_by = 'mean'
    end

    # direction
    if(params[:direction] and %w[asc desc].include?(params[:direction]))
      @direction = params[:direction]
    else
      @direction = 'desc'
    end

    @pagelist = scope.totals_list({order_by: @order_by, direction: @direction}).page(params[:page])

    @page_title_display = @page_title = "#{@datatype} Page Totals"
    @endpoint = "Page Totals"

    if(@group)
      @page_title += " - Group ##{@group.id}"
      @page_title_display += " for #{@group.name}"
    end
  end

  def aggregate
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      # for now, error later
      @datatype = 'Article'
    end

    # todo: contributor, tags
    if(@group)
      scope = @group.collected_page_stats.by_datatype(@datatype).by_metric(@metric)
    else
      scope = CollectedPageStat.overall.by_datatype(@datatype).by_metric(@metric)
    end

    # order_by
    allowed_columns = CollectedPageStat.column_names  + ['seen_pct']
    if(params[:order_by] and allowed_columns.include?(params[:order_by]))
      @order_by = params[:order_by]
    else
      @order_by = 'yearweek'
    end

    # direction
    if(params[:direction] and %w[asc desc].include?(params[:direction]))
      @direction = params[:direction]
    else
      @direction = 'asc'
    end

    @statlist = scope.with_seen_pct.order("#{@order_by} #{@direction}").page(params[:page])

    case @metric
    when 'unique_pageviews'
      metric_label = 'View'
    else
      metric_label = @metric.titleize
    end

    @page_title_display = @page_title = "#{@datatype} Page #{metric_label} Aggregates By Week"
    @endpoint = "Page #{metric_label} Aggregates By Week"

    if(@group)
      @page_title += " - Group ##{@group.id}"
      @page_title_display += " for #{@group.name}"
    end
  end

  def panda_impact_summary
    if(!params[:weeks].nil?)
      @panda_comparison_weeks =  params[:weeks].to_i
    else
      @panda_comparison_weeks = 3
    end
    @diffs = CollectedPageStat.panda_impacts(@panda_comparison_weeks)
  end


  def setdate
    if(params[:date])
      begin
        @date = Date.parse(params[:date])
        session[:date] = @date.to_s
      rescue
        # nothing
      end
    end

    if(!params[:currenturi].nil?)
      return redirect_to(Base64.decode64(params[:currenturi]))
    else
      return redirect_to(root_url)
    end
  end

  def comparison_test
    @stats = YearWeekStatsComparator.new
    @stats['News'] = Page.news.stats_by_yearweek('unique_pageviews')
    @stats['Indexed News'] = Page.news.indexed.stats_by_yearweek('unique_pageviews')
  end

  protected

  def check_for_group
    if(params[:group_id])
      @group = Group.find(params[:group_id])
    end
    true
  end







end