# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class HomeController < ApplicationController
  skip_before_filter :check_for_rebuild,  only: [:index]

  def index
    @rebuild = Rebuild.latest
    if(@rebuild.in_progress?)
      @hide_navbar = true
      return render :template => 'home/rebuild_in_progress'
    else
      # pages
      @seen = CollectedPageStat.overall.latest_week.where(metric: @metric).pluck(:seen).sum
      @seen_page_views = CollectedPageStat.overall.latest_week.where(metric: @metric).pluck(:total).sum
      @home_views = LandingStat.overall.latest_week.first.send(@metric)
      @group_views = LandingStat.where('group_id > 0').latest_week.sum("#{@metric}")
      @groups_viewed = LandingStat.where('group_id > 0').where("#{@metric} > 0").latest_week.count
      @total_views = (@seen_page_views + @home_views + @group_views).to_i

      # nodes
      @last_week_node_stats = {}
      NodeActivity::ACTIVITIES.each do |activity|
        @last_week_node_stats[activity] = Node.latest_activity.overall_stats(activity)
      end

      # groups
      @group_members = ContributorGroup.joins(:group).where('groups.is_launched = ?',true).count('DISTINCT(contributor_id)')
      @group_pages = CollectedPageStat.where(metric: @metric).latest_week.where('statable_type = ?','Group').group('statable_id').sum('pages').values.mean.round
      @top_page = Page.top_pages({by: 'this_week', limit: 1}).first

    end
   end

  def search
    @search_results_count = 0
    if(params[:q])
      if(params[:q].cast_to_i > 0)
        @search_type = 'numeric'
        @id_number = params[:q].cast_to_i
        if(@page = Page.find_by_id(@id_number))
          @search_results_count += 1
        end
        if(@node = Node.find_by_id(@id_number))
          @search_results_count += 1
        end
        if(@contributor = Contributor.find_by_id(@id_number))
          @search_results_count += 1
        end

        # single result? - go straight to item
        if(@search_results_count == 1)
          return redirect_to(page_path(@page)) if @page
          return redirect_to(node_path(@node)) if @node
          return redirect_to(contributor_path(@contributor)) if @contributor
        end
      else
        @search_type = 'text'
        # copied from darmok - need to review - see Contributor patternsearch scope for details
        sanitizedsearchterm = params[:q].gsub(/\\/,'').gsub(/^\*/,'$').gsub(/\+/,'').gsub(/\(/,'').gsub(/\)/,'').strip

        like= "%".concat(sanitizedsearchterm.concat("%"))
        @pagelist = Page.where("title like ?", like)
        @nodelist = Node.where("title like ?", like)
        @contributorlist = Contributor.patternsearch(params[:q])
        @search_results_count = @pagelist.count + @nodelist .count + @contributorlist.count
      end
    end
  end


end
