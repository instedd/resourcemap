class HomeController < ApplicationController
  after_action :intercom_shutdown, only: [:index]

  def index
    redirect_to collections_path if !current_user.is_guest && !params[:explicit]
  end

  protected
  def intercom_shutdown
    IntercomRails::ShutdownHelper.intercom_shutdown(session, cookies, request.domain)
  end
end
