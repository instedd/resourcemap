class ApplicationController < ActionController::Base
  protect_from_forgery

  expose(:collections) { current_user.collections }
  expose(:collection)
  expose(:collection_memberships) { collection.memberships.includes(:user) }
  expose(:layers) { collection.layers }
  expose(:layer)
  expose(:fields) { collection.fields }
  expose(:activities) { current_user.activities }
  expose(:thresholds) { collection.thresholds.order :ord }
  expose(:threshold)

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || collections_path
  end

  def authenticate_collection_admin!
    head :unauthorized unless current_user.admins?(collection)
  end

  def authenticate_site_user!
    head :unauthorized unless current_user.belongs_to?(site.collection)
  end
end
