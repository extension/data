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
    #@is_staff = @currentcontributor.groups.include?(Group.find(Group::EXTENSION_STAFF))
    @download = Download.find_by_label('aae_evaluation')
  end

  def getfile
    @download = Download.find(params[:id])
    if(@download.label == 'aae_evaluation')
      if(!@currentcontributor.groups.include?(Group.find(Group::EXTENSION_STAFF)))
        flash[:notice] = 'This export is currently restricted to staff only.'
        return redirect_to(downloads_url)
      end
    end        

    if(@download.in_progress?)
      flash[:notice] = 'This export is currently in progress. Check back in a few minutes.'
      return redirect_to(downloads_url)
    elsif(!@download.updated?)
      @download.delay.dump_to_file
      flash[:notice] = 'This export has not been updated. Check back in a few minutes.'
      return redirect_to(downloads_url)
    else
      send_file(@download.filename,
                :type => 'text/csv; charset=iso-8859-1; header=present',
                :disposition => "attachment; filename=#{File.basename(@download.filename)}")
    end
  end

  
end