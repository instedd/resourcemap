class AnalyticsController < ApplicationController
  def index
    @analytics = User.order("confirmation_sent_at DESC").page(params[:page]).per_page(15)
    respond_to do |format|
      format.html
    end
  end
end
