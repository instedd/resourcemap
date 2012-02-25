class HomeController < ApplicationController
  def index
    redirect_to collections_path if current_user && !params[:explicit]
  end
end
