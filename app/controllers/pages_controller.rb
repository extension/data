# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file
require 'csv'

class PagesController < ApplicationController
  before_filter :check_for_group

  def index
    @landing_stats = LandingStat.overall.stats_by_yearweek(@metric)
    @datatype_stats = YearWeekStatsComparator.new
    Page::DATATYPES.each do |datatype|
      @datatype_stats[datatype] = Page.by_datatype(datatype).stats_by_yearweek(@metric)
    end
  end

  def overview
    if(params[:contributor_id] and @contributor = Contributor.find_by_id(params[:contributor_id]))
      if(params[:contributions] and params[:contributions] == 'meta')
        @contributions_type = 'Listed'
        scope = @contributor.unique_meta_contributed_pages
      else
        @contributions_type = 'Direct'
        scope = @contributor.unique_contributed_pages
      end
    elsif(@group)
      scope = @group.pages
    elsif(params[:tag] and @tag = Tag.find_by_name(params[:tag]))
      scope = @tag.pages
    else
      scope = Page
    end

    @page_title_display = @page_title = "Page Information"

    if(@contributor)
      @page_title += "- #{@contributions_type} Contributions - #{@contributor.fullname} (ID##{@contributor.id})"
      @page_title_display += "- #{@contributions_type} Contributions for #{@contributor.fullname}"
    elsif(@group)
      @page_title += " - Group ##{@group.id}"
      @page_title_display += " for #{@group.name}"
    elsif(@tag)
      @page_title += " - Tag ##{@tag.id}"
      @page_title_display += " for #{@tag.name}"     
    end

    @endpoint = @page_title

    @datatype_stats = {}
    @overall_stats = {}
    @comparators = {}
    Page::DATATYPES.each do |datatype|
      @datatype_stats[datatype] = scope.by_datatype(datatype).stats_by_yearweek(@metric)
      @overall_stats[datatype] = Page.by_datatype(datatype).stats_by_yearweek(@metric)
      @comparators[datatype]= YearWeekStatsComparator.new
      @comparators[datatype]["Overall #{datatype.pluralize}"] = @overall_stats[datatype]
      @comparators[datatype]["#{datatype.pluralize}"] = @datatype_stats[datatype]
    end
  end

  def show
    @page = Page.includes(:node).find(params[:id])
    @view_stats = @page.stats_by_yearweek(@metric)
  end

  def details
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype) and @datatype != 'All')
      # ToDo: error out
      @datatype = 'Article'
    end

    if(params[:contributor_id] and @contributor = Contributor.find_by_id(params[:contributor_id]))
      if(params[:contributions] and params[:contributions] == 'meta')
        @contributions_type = 'Listed'
        scope = @contributor.unique_meta_contributed_pages.by_datatype(@datatype)
      else
        @contributions_type = 'Direct'
        scope = @contributor.unique_contributed_pages.by_datatype(@datatype)
      end
    elsif(@group)
      scope = @group.pages.by_datatype(@datatype)
    elsif(params[:tag] and @tag = Tag.find_by_name(params[:tag]))
      scope = @tag.pages.by_datatype(@datatype)
    else
      scope = Page.by_datatype(@datatype)
    end

    @page_title_display = @page_title = "#{@datatype} Details"
    @endpoint = @datatype.pluralize

    if(@contributor)
      @page_title += "- #{@contributions_type} Contributions - #{@contributor.fullname} (ID##{@contributor.id})"
      @page_title_display += "- #{@contributions_type} Contributions for #{@contributor.fullname}"
    elsif(@group)
      @page_title += " - Group ##{@group.id}"
      @page_title_display += " for #{@group.name}"
    elsif(@tag)
      @page_title += " - Tag ##{@tag.id}"
      @page_title_display += " for #{@tag.name}"     
    end

    @stats = scope.stats_by_yearweek(@metric)
    @percentiles = scope.percentiles_by_yearweek(@metric)
  end


  def totals
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype) and @datatype != 'All')
      # for now, error later
      @datatype = 'Article'
    end

    if(params[:contributor_id] and @contributor = Contributor.find_by_id(params[:contributor_id]))
      if(params[:contributions] and params[:contributions] == 'meta')
        @contributions_type = 'Listed'
        scope = @contributor.unique_meta_contributed_pages.by_datatype(@datatype)
      else
        @contributions_type = 'Direct'
        scope = @contributor.unique_contributed_pages.by_datatype(@datatype)
      end
    elsif(@group)
      scope = @group.pages.by_datatype(@datatype)
    elsif(params[:tag] and @tag = Tag.find_by_name(params[:tag]))
      scope = @tag.pages.by_datatype(@datatype)
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

    case @metric
    when 'unique_pageviews'
      metric_label = 'View'
    else
      metric_label = @metric.titleize
    end

    @page_title_display = @page_title = "#{@datatype} Page #{metric_label} Totals"
    @endpoint = "Page #{metric_label} Totals"

    if(@contributor)
      @page_title += "- #{@contributions_type} Contributions - #{@contributor.fullname} (ID##{@contributor.id})"
      @page_title_display += "- #{@contributions_type} Contributions for #{@contributor.fullname}"
    elsif(@group)
      @page_title += " - Group ##{@group.id}"
      @page_title_display += " for #{@group.name}"
    elsif(@tag)
      @page_title += " - Tag ##{@tag.id}"
      @page_title_display += " for #{@tag.name}"     
    end


    if(!params[:download].nil? and params[:download] == 'csv')
      @node_contributors = NodeActivity.joins(:node).where('nodes.has_page = 1').group('node_id').count('contributor_id',:distinct => true)
      @node_contributions = NodeActivity.joins(:node).where('nodes.has_page = 1').group('node_id').count('node_activities.id')
      @pagelist = @pagelist = scope.totals_list({order_by: @order_by, direction: @direction, metric: @metric})
      send_data(totals_csv(@pagelist,@node_contributors,@node_contributions),
                :type => 'text/csv; charset=iso-8859-1; header=present',
                :disposition => "attachment; filename=#{@page_title_display.downcase.gsub(' ','_')}.csv")
    else
      @pagelist = scope.totals_list({order_by: @order_by, direction: @direction, metric: @metric}).page(params[:page])
    end


  end

  def aggregate
    @datatype = params[:datatype]
    if(!Page::DATATYPES.include?(@datatype))
      # for now, error later
      @datatype = 'Article'
    end

    # todo: tags
    # contributors are likely a no-go for now
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

    if(!params[:download].nil? and params[:download] == 'csv')
      @statlist = scope.with_seen_pct.order("#{@order_by} #{@direction}")
      send_data(aggregate_csv(@statlist),
                :type => 'text/csv; charset=iso-8859-1; header=present',
                :disposition => "attachment; filename=#{@page_title_display.downcase.gsub(' ','_')}.csv")
    else
      @statlist = scope.with_seen_pct.order("#{@order_by} #{@direction}").page(params[:page])
    end
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

  def publishedcontent
    @page_counts = {}
    Page::DATATYPES.each do |datatype|
      @page_counts[datatype] = Page.counts_by_group_for_datatype(datatype)
    end
  end

  protected

  def check_for_group
    if(params[:group_id])
      @group = Group.find(params[:group_id])
    end
    true
  end

  def totals_csv(collection,contributors,contributions)
    CSV.generate do |csv|
      headers = []
      Page.totals_list_columns.each do |column|
        headers << column
      end
      headers << 'contributors'
      headers << 'contributions'
      csv << headers
      collection.each do |page|
        row = []
        Page.totals_list_columns.each do |column|
          value = page.send(column)
          if(value.is_a?(Time))
            row << value.strftime("%Y-%m-%d %H:%M:%S")
          else
            row << value
          end
        end
        if(page.node_id)
          row << contributors[page.node_id] || 0
          row << contributions[page.node_id] || 0
        else
          row << 'n/a'
          row << 'n/a'
        end
        csv << row
      end
    end
  end

  def aggregate_csv(collection)
    column_list = CollectedPageStat.column_names  + ['seen_pct']
    CSV.generate do |csv|
      headers = []
      column_list.each do |column|
        headers << column
      end
      csv << headers
      collection.each do |page|
        row = []
        column_list.each do |column|
          value = page.send(column)
          if(value.is_a?(Time))
            row << value.strftime("%Y-%m-%d %H:%M:%S")
          else
            row << value
          end
        end
        csv << row
      end
    end
  end

end