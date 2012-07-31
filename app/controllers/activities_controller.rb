class ActivitiesController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json do
        acts = Activity.order('id desc').includes(:collection, :site, :user)
        acts = acts.limit(25)
        acts = acts.where('id < ?', params[:before_id]) if params[:before_id]

        if params[:collection_ids]
          acts = acts.where(collection_id: params[:collection_ids])
        else
          acts = acts.where(collection_id: current_user.memberships.pluck(:collection_id))
        end

        if params[:kinds]
          acts = acts.where("CONCAT(item_type, ',', action) IN (?)", params[:kinds])
        end

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
