# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
class DataController < ApplicationController
  
  def groups
    if params[:term]
      like= "%".concat(params[:term].concat("%"))
      groups = Group.launched.where("name like ?", like)
    else
      groups = Group.all
    end
    list = groups.map {|g| Hash[ id: g.id, label: g.name, name: g.name]}
    render json: list
  end

end
