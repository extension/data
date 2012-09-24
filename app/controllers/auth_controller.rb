# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
class AuthController < ApplicationController
  skip_before_filter :signin_required
  skip_before_filter :verify_authenticity_token

  def start
  end

  def end
    @currentcontributor = nil
    session[:contributor_id] = nil
    flash[:success] = "You have successfully signed out."
    return redirect_to(root_url)
  end

  def success
    authresult = request.env["omniauth.auth"]
    provider = authresult['provider']
    uid = authresult['uid']

    contributor = Contributor.find_by_uid(uid,provider)

    if(contributor)
      contributor.login
      session[:contributor_id] = contributor.id
      @currentcontributor = contributor
      flash[:success] = "You are signed in as #{@currentcontributor.fullname}"
    else
      flash[:error] = "Unable to find your account, please contact an Engineering staff member to create your account"
    end

    return redirect_to(root_url)

  end

  def failure
    raise request.env
  end



end
