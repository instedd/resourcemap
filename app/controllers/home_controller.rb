class HomeController < ApplicationController
  def index
    redirect_to collections_path if !current_user.is_guest && !params[:explicit]
  end
end
