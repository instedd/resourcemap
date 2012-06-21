class ApplicationController < ActionController::Base
  protect_from_forgery

  expose(:collections) { current_user.collections }
  expose(:collection)
  expose(:current_snapshot) { collection.snapshot_for(current_user) }
  expose(:collection_memberships) { collection.memberships.includes(:user) }
  expose(:layers) {if current_snapshot && collection then collection.layer_histories.at_date(current_snapshot.date) else collection.layers end}
  expose(:layer)
  expose(:fields) {if current_snapshot && collection then collection.field_histories.at_date(current_snapshot.date) else collection.fields end}
  expose(:activities) { current_user.activities }
  expose(:thresholds) { collection.thresholds.order :ord }
  expose(:threshold)
  expose(:reminders) { collection.reminders }
  expose(:reminder)

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || collections_path
  end

  def authenticate_collection_admin!
    head :unauthorized unless current_user.admins?(collection)
  end

  def authenticate_site_user!
    head :unauthorized unless current_user.belongs_to?(site.collection)
  end

  def show_collections_breadcrumb
    @show_breadcrumb = true
    add_breadcrumb "Collections", collections_path
  end

  def show_collection_breadcrumb
    show_collections_breadcrumb
    add_breadcrumb collection.name, collection_path(collection)
  end
end
