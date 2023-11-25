class CollectionsController < ApplicationController

  authorize_resource :except => [:render_breadcrumbs], :decent_exposure => true, :id_param => :collection_id

  # we cannot call this exposure 'collections' becuause if we do,
  # decent_exposure will load the "collection" from "collections"
  # and (becuase of collections is loaded using a JOIN)
  # then the "collection" is going to have a readonly=true value
  # https://github.com/rails/rails/pull/10769 && https://github.com/ryanb/cancan/issues/357
  expose(:accessible_collections) { Collection.accessible_by(current_ability)}

  expose(:collections_with_snapshot) { select_each_snapshot(accessible_collections.uniq) }

  before_action :show_collections_breadcrumb, :only => [:index, :new]
  before_action :show_collection_breadcrumb, :except => [:index, :new, :create, :render_breadcrumbs]
  before_action :show_properties_breadcrumb, :only => [:members, :settings, :reminders]

  def index
    # Keep only the collections of which the user is membership
    # since the public ones are accessible also, but should not be listed in the collection's view
    user_memberships = current_user.memberships.map{|c| c.collection_id.to_s}
    collections_with_snapshot_by_user = collections_with_snapshot.select{|col| user_memberships.include?(col["id"].to_s)}

    add_breadcrumb _("Collections"), 'javascript:window.model.goToRoot()'
    respond_to do |format|
      format.html do
        if current_user.is_guest
          redirect_to_login if !params[:collection_id].present? || !collection.public?
        end
      end

      format.json { render_json collections_with_snapshot_by_user }
    end
  end

  def import_layers_from
    the_other_collection = Collection.find params[:other_id]

    notice_text = _("Imported layers from %{collection_name}") % { collection_name: the_other_collection.name }

    redirect_to collection_layers_path(collection), notice: notice_text unless current_user.admins? the_other_collection

    #TODO: refactor :)
    json_layers = the_other_collection.layers.includes(:fields).as_json(include: :fields).to_json

    collection.import_schema json_layers, current_user
    redirect_to collection_layers_path(collection), notice: notice_text
  end

  def current_user_membership
    respond_to do |format|
      format.json { render json: collection.membership_for(current_user).to_json }
    end
  end

  def render_breadcrumbs
    add_breadcrumb _("Collections"), 'javascript:window.model.goToRoot()' if current_user && !current_user.is_guest
    if params.has_key? :collection_id
      add_breadcrumb collection.name, 'javascript:window.model.exitSite()'
      if params.has_key? :site_id
        add_breadcrumb params[:site_name], '#'
      end
    end
    render :layout => false
  end

  def new
    add_breadcrumb _("Collections"), collections_path
    add_breadcrumb _("Create new collection"), nil
  end

  def create
    if current_user.create_collection collection
      current_user.collection_count += 1
      current_user.update_successful_outcome_status
      current_user.save!
      respond_to do |format|
        format.html { redirect_to collection_path(collection), notice: _("Collection %{collection_name} created") % {collection_name: collection.name} }
        format.json { render_json collection }
      end
    else
      render :new
    end
  end

  def update
    if collection.update_attributes params[:collection]
      collection.recreate_index
      redirect_to collection_settings_path(collection), notice: _("Collection %{collection_name} updated") % { collection_name: collection.name }
    else
      render :settings
    end
  end

  def show
    @snapshot = Snapshot.new
    add_breadcrumb _("Properties"), '#'
    respond_to do |format|
      format.html
      format.json { render_json collection }
    end
  end

  def members
    add_breadcrumb _("Members"), collection_members_path(collection)
  end

  def reminders
    add_breadcrumb _("Reminders"), collection_reminders_path(collection)
  end

  def settings
    add_breadcrumb _("Settings"), collection_settings_path(collection)
  end

  def quotas
    add_breadcrumb _("Quotas"), collection_settings_path(collection)
  end

  def destroy
    if params[:only_sites]
      collection.delete_sites_and_activities
      redirect_to collection_path(collection), notice: _("Collection %{collection_name}'s sites deleted") % {collection_name: collection.name}
    else
      collection.destroy
      redirect_to collections_path, notice: _("Collection %{collection_name} deleted") % {collection_name: collection.name}
    end
  end

  def csv_template
    send_data collection.csv_template, type: 'text/csv', filename: "collection_sites_template.csv"
  end

  def create_snapshot
    @snapshot = Snapshot.create(date: Time.now, name: params[:snapshot][:name], collection: collection)
    if @snapshot.valid?
      redirect_to collection_path(collection), notice: _("Snapshot %{name} created") % {name: params[:name] }
    else
      flash[:error] = _("Snapshot could not be created: %{errors}") % {errors: @snapshot.errors.to_a.join(", ")}
      redirect_to collection_path(collection)
    end
  end

  def unload_current_snapshot
    loaded_snapshot = current_user_snapshot.snapshot
    current_user_snapshot.go_back_to_present!

    respond_to do |format|
      format.html do
        flash[:notice] = _("Snapshot %{snapshot_name} unloaded") % {snapshot_name: loaded_snapshot.name} if loaded_snapshot
        redirect_to(params[:next_url] || collection_path(collection))
      end
      format.json { render_json :ok }
    end
  end

  def load_snapshot
    if current_user_snapshot.go_to!(params[:snapshot_id])
      flash[:notice] = _("Snapshot %{name} loaded") % {name: current_user_snapshot.snapshot.name}
    else
      flash[:error] = _("Snapshot not found")
    end
    redirect_to collection
  end

  def max_value_of_property
    render_json collection.max_value_of_property(params[:property])
  end

  def select_each_snapshot(collections)
    collections_with_snapshot = []

    if current_user && current_user.id
      # Fetch all snapshots names at once instead of fetching them one by one for each collection
      snapshot_names = Snapshot.names_for_collections_and_user(collections, current_user)
    else
      # If user is guest (=> current_user will be nil) she will not be able to load a snapshot. At least for the moment
      snapshot_names = {}
    end

    collections.each do |collection|
      attrs = collection.attributes
      attrs["logo_url"] = collection.logo_url(:grayscale)
      attrs["snapshot_name"] = snapshot_names[collection.id]
      collections_with_snapshot.push attrs
    end
    collections_with_snapshot
  end

  def sites_by_term
    search = new_search

    search.full_text_search params[:term] if params[:term]
    search.select_fields(['id', 'name'])
    results = search.results.map { |item| item["fields"] }
    results.each do |item|
      item[:value] = item["name"]
    end

    render_json results
  end

  def search
    search = new_search

    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search]
    search.offset params[:offset]
    search.limit params[:limit]
    search.sort params[:sort], params[:sort_direction] != 'desc' if params[:sort]
    search.hierarchy params[:hierarchy_code], params[:hierarchy_value] if params[:hierarchy_code]
    search.location_missing if params[:location_missing].present?
    search.name_search params[:sitename] if params[:sitename].present?
    search.where params.except(:action, :controller, :format, :id, :collection_id, :updated_since, :search, :limit, :offset, :sort, :sort_direction, :hierarchy_code, :hierarchy_value, :location_missing, :locale, :sitename)
    results = search.results
    sites = results.map do |result|
      source = result['_source']

      obj = {}
      obj[:id] = source['id']
      obj[:name] = source['name']
      obj[:created_at] = Site.parse_time(source['created_at'])
      obj[:updated_at] = Site.parse_time(source['updated_at'])

      if source['location']
        obj[:lat] = source['location']['lat']
        obj[:lng] = source['location']['lon']
      end

      if source['properties']
        obj[:properties] = source['properties']
      end

      obj
    end
    render_json({ sites: sites, total_count: results.total_count })
  end

  def recreate_index
    render_json collection.recreate_index
  end

  def register_gateways
    collection.channels = Channel.find params["gateways"]
    render_json collection
  end

  def message_quota
    date = Date.today
    case params[:filter_type]
    when "week"
      start_date = date - 7
    when "month"
      start_date = date.prev_month
    else
      start_date = date.prev_year
    end
    ection.messages.where("is_send = true and created_at between ? and ?", start_date, Time.now)
    render_json({status: 200, remain_quota: collection.quota, sended_message: ms.length})
  end

  def sites_info
    options = new_search_options

    total = collection.elasticsearch_count do
      {
        query: {
          filtered: {
            filter: {
              missing: {field: "deleted_at"}
            }
          }
        }
      }
    end

    no_location = collection.elasticsearch_count do
      {
        query: {
          filtered: {
            filter: {
              and: [
                {missing: {field: "deleted_at"}},
                {not: {filter: {exists: {field: :location}}}}
              ]
            }
          }
        }
      }
    end

    info = {}
    info[:total] = total
    info[:no_location] = no_location > 0
    info[:new_site_properties] = collection.new_site_properties

    render_json info
  end

  # Accept a file logo upload and save it to temporary storage (CarrierWave cache).
  # The client-side code in settings.coffee deals with attaching the temporary
  # file to the collection being edited/created.
  def upload_logo
    uploader = LogoUploader.new
    uploader.cache! params[:logo]

    render_json({cache_name: uploader.cache_name,
                 croppable_url: uploader.url(:croppable),
                 preview_url: uploader.url(:preview)})
  end

end
