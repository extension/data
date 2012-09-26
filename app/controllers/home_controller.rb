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
