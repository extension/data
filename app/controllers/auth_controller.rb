# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
class AuthController < ApplicationController
  # skip_before_filter :signin_required

  def start
  end
    
  def end
    @currentcoder = nil
    session[:coder_id] = nil
    flash[:success] = "You have successfully signed out."
    return redirect_to(root_url)
  end
  
  def success
    authresult = request.env["omniauth.auth"]    
    uid = authresult['uid']
    email = authresult['info']['email']
    name = authresult['info']['name']
    nickname = authresult['info']['nickname']
    
    if(email.blank?)
      flash[:error] = "You'll need to set a public email address for your GitHub account matched with your .gitconfig settings to sign in here."
      return redirect_to(root_url)
    end
      
    coder = Coder.find_by_email(email)
    
    if(coder)
      # update uid, nickname, name, it's possible the coder was created
      # from commits, and not via login
      coder.update_attributes(:uid => uid, :nickname => nickname, :name => name)
      coder.login
      session[:coder_id] = coder.id
      @currentcoder = coder
    else
      coder = Coder.create(:uid => uid, :email => email, :nickname => nickname, :name => name)
      if(coder)
        coder.login
        session[:coder_id] = coder.id
        @currentcoder = coder
      end
    end
  
    flash[:success] = "You are signed in as #{@currentcoder.name}"
    return redirect_to(root_url)

  end
  
  def failure
    raise request.env
  end
  
  

end
