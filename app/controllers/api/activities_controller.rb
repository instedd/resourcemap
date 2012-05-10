class Api::ActivitiesController < ApplicationController
  PerPage = 50

  def index
    @page = (params[:page] || '1').to_i
    @activities = activities.order('id desc').includes(:collection, :user)
    @activities = @activities.limit(PerPage + 1)
    if @page > 1
      @activities.offset((@page - 1) * PerPage)
    end
    @activities = @activities.all

    if @activities.length == PerPage + 1
      @hasNextPage = true
      @activities = @activities[0 .. -2]
    end

    render :index, layout: false
  end
end
