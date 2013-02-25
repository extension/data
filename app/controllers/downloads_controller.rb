# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DownloadsController < ApplicationController
  before_filter :signin_required

  def index
  end

  def aae_questions
    @download = Download.find_by_label('aae_questions')
  end

  def aae_evaluation
    @download = Download.find_by_label('aae_evaluation')
  end

  def getfile
    @download = Download.find(params[:id])
    if(@download.in_progress?)
      flash[:notice] = 'This export is currently in progress. Check back in a few minutes.'
      return redirect_to(index_url)
    elsif(!@download.updated?)
      @download.delay.dump_to_file
      flash[:notice] = 'This export has not been updated. Check back in a few minutes.'
      return redirect_to(index_url)
    else
      send_file(@download.filename,
                :type => 'text/csv; charset=iso-8859-1; header=present',
                :disposition => "attachment; filename=#{File.basename(@download.filename)}")
    end
  end

  
end