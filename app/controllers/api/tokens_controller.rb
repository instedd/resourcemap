class Api::TokensController < ApplicationController
  before_filter :authenticate_user!

  def index 
    render :json => {:token => current_user.authentication_token}
  end

  def destroy
    current_user.reset_authentication_token!
  end
  
end
