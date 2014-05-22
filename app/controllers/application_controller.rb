class ApplicationController < ActionController::Base
  protect_from_forgery

  expose(:collection)
  expose(:current_user_snapshot) { UserSnapshot.for current_user, collection }
  expose(:collection_memberships) { collection.memberships.includes(:user) }
  expose(:fields) {if !current_user_snapshot.at_present? && collection then collection.field_histories.at_date(current_user_snapshot.snapshot.date) else collection.fields end}
  expose(:activities) { current_user.activities }
  expose(:thresholds) { collection.thresholds.order :ord }
  expose(:threshold)
  expose(:reminders) { collection.reminders }
  expose(:reminder)

  before_filter :set_gettext_locale
  before_filter :redirect_to_localized_url

  expose(:new_search_options) do
    if current_user_snapshot.at_present?
      {current_user: current_user}
    else
      {snapshot_id: current_user_snapshot.snapshot.id, current_user_id: current_user.id}
    end
  end
  expose(:new_search) { collection.new_search new_search_options }

  rescue_from ActiveRecord::RecordNotFound do |x|
    respond_to do |format|
      format.html { render :file => '/error/doesnt_exist_or_unauthorized', :status => 404, :layout => true }
      format.json { render_json({ message: "Record not found"}, status: 404) }
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html {
        if current_user.is_guest
          authenticate_user!
        else
         render :file => '/error/doesnt_exist_or_unauthorized', :alert => exception.message, :status => :forbidden
        end
      }
      format.json { render_json({ message: "Access Denied"}, status: 404) }
    end
  end

  def guest_user
    @guest_user ||= User.new(is_guest: true)
  end

  def current_user
    super || guest_user
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || collections_path
  end

  def authenticate_collection_user!
    head :forbidden unless current_user.belongs_to?(collection)
  end

  def authenticate_collection_admin!
    head :unauthorized and return if current_user.is_guest
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
    add_breadcrumb _("Collections"), collections_path
    add_breadcrumb collection.name, collections_path + "?collection_id=#{collection.id}"
  end

  def show_properties_breadcrumb
    add_breadcrumb _("Properties"), collection_path(collection)
  end

  # Faster way to render json, using the Oj library.
  # There is a way to let render :json use Oj by default,
  # but in my tests it turned out to be slower... - Ary
  def render_json(object, options = {})
    options = options.merge(text: object.to_json_oj, content_type: 'application/json')
    render options
  end

  def redirect_to_localized_url
    redirect_to params if params[:locale].nil? && request.get?
  end

  def default_url_options(options={})
    {:locale => I18n.locale.to_s}
  end
end
