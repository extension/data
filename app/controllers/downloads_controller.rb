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
    eligible_questions = Question.where(evaluation_eligible: true).pluck(:id)
    response_questions = AaeEvaluationAnswer.pluck(:question_id).uniq
    eligible_response_questions = eligible_questions & response_questions
    @response_rate = {eligible: eligible_questions.size, responses: eligible_response_questions.size}
  end

  def aae_demographics
    @download = Download.find_by_label('aae_demographics')
    eligible_submitters = Question.where(demographic_eligible: true).pluck(:submitter_id).uniq
    response_submitters = AaeDemographic.pluck(:user_id).uniq
    eligible_response_submitters = eligible_submitters & response_submitters
    @response_rate = {eligible: eligible_submitters.size, responses: eligible_response_submitters.size}    
  end    

  def aae_demographics_private
    @is_staff = @currentcontributor.groups.include?(Group.find(Group::EXTENSION_STAFF))
    @download = Download.find_by_label('aae_demographics_private')
    eligible_submitters = Question.where(demographic_eligible: true).pluck(:submitter_id).uniq
    response_submitters = AaeDemographic.pluck(:user_id).uniq
    eligible_response_submitters = eligible_submitters & response_submitters
    @response_rate = {eligible: eligible_submitters.size, responses: eligible_response_submitters.size}        
  end    

  def getfile
    @download = Download.find(params[:id])
    if(@download.label == 'aae_demographics_private')
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