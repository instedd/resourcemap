class ActivitiesController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json do
        acts = activities.order('id desc').includes(:collection, :user)
        acts = acts.limit(25)
        acts = acts.where('id < ?', params[:before_id]) if params[:before_id]
        activities_json = acts.map do |activity|
          {
            id: activity.id,
            collection: activity.collection.name,
            user: activity.user.display_name,
            description: activity.description,
            created_at: activity.created_at
          }
        end
        render json: activities_json
      end
    end
  end
end
