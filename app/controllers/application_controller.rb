class ApplicationController < ActionController::Base
  protect_from_forgery

  #expose(:collection) { (Collection.find(params[:collection] || params[:collection_id] || params[:id])) if params[:collection]|| params[:collection_id] || params[:id] }
  expose(:collection)
  expose(:current_snapshot) { collection.snapshot_for(current_user) if current_user }
  expose(:collection_memberships) { collection.memberships.includes(:user) }
  expose(:layers) {if current_snapshot && collection then collection.layer_histories.at_date(current_snapshot.date) else collection.layers end}
  expose(:layer)
  expose(:fields) {if current_snapshot && collection then collection.field_histories.at_date(current_snapshot.date) else collection.fields end}
  expose(:activities) { current_user.activities }
  expose(:thresholds) { collection.thresholds.order :ord }
  expose(:threshold)
  expose(:reminders) { collection.reminders }
  expose(:reminder)

  rescue_from ActiveRecord::RecordNotFound do |x|
    render :file => '/error/doesnt_exist_or_unauthorized', :status => 404, :layout => true
  end

  rescue_from CanCan::AccessDenied do |exception|
    render :file => '/error/doesnt_exist_or_unauthorized', :alert => exception.message, :status => :forbidden
  end

  def setup_guest_user
    @guest_user = User.new is_guest: true
  end

  def current_user
    super || @guest_user
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || collections_path
  end

  def authenticate_collection_user!
    head :forbidden unless current_user.belongs_to?(collection)
  end

  def authenticate_collection_admin!
    head :forbidden unless current_user.admins?(collection)
  end

  def authenticate_site_user!
    head :forbidden unless current_user.belongs_to?(site.collection)
  end

  def show_collections_breadcrumb
    @show_breadcrumb = true
  end

  def show_collection_breadcrumb
    show_collections_breadcrumb
    add_breadcrumb "Collections", collections_path
    add_breadcrumb collection.name, collections_path + "?collection=#{collection.id}"
  end

  def show_properties_breadcrumb
    add_breadcrumb "Properties", collection_path(collection)
  end
end
