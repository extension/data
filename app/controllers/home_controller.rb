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
    if(params[:q])
      if(params[:q].to_i > 0)
        @id_number = params[:q].to_i
        @page = Page.find_by_id(@id_number)
        @node = Node.find_by_id(@id_number)
        if(@page and !@node)
          return redirect_to(page_path(@page))
        elsif(@node and !@page and !@node.page.nil?)
          return redirect_to(node_path(@node))
        end
      else
        like= "%".concat(params[:q].concat("%"))
        @pagelist = Page.where("title like ?", like)
      end
    end
  end


end
