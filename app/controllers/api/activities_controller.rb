class Api::ActivitiesController < ApplicationController
  PerPage = 50

  def index
    @page = (params[:page] || '1').to_i
    @activities = Activity.order('id desc').includes(:collection, :site, :user)
    @activities = @activities.limit(PerPage + 1)
    if @page > 1
      @activities.offset((@page - 1) * PerPage)
    end

    if params[:collection_ids]
      @activities = @activities.where(collection_id: params[:collection_ids])
    else
      @activities = @activities.where(collection_id: current_user.memberships.pluck(:collection_id))
    end

    if params[:kinds]
      @activities = @activities.where("CONCAT(item_type, ',', action) IN (?)", params[:kinds])
    end

    @activities = @activities.all

    if @activities.length == PerPage + 1
      @hasNextPage = true
      @activities = @activities[0 .. -2]
    end

    render :index, layout: false
  end
end
