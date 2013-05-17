class CollectionsController < ApplicationController
  before_filter :current_user_or_guest, :only => [:index]
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, :only => [:destroy, :create_snapshot]
  before_filter :show_collections_breadcrumb, :only => [:index, :new]
  before_filter :show_collection_breadcrumb, :except => [:index, :new, :create, :render_breadcrumbs]
  before_filter :show_properties_breadcrumb, :only => [:members, :settings, :reminders]

  def index
    if params[:name].present?
      render json: Collection.where("name like ?", "%#{params[:name]}%") if params[:name].present?
    else
      add_breadcrumb "Collections", 'javascript:window.model.goToRoot()' if !current_user.is_guest
      respond_to do |format|
        format.html
        collections_with_snapshot = []
        collections.all.each do |collection|
          attrs = collection.attributes
          attrs["snapshot_name"] = collection.snapshot_for(current_user).try(:name)
          collections_with_snapshot = collections_with_snapshot + [attrs]
        end
        format.json {render json: collections_with_snapshot }
      end
    end
  end

  def render_breadcrumbs
    add_breadcrumb "Collections", 'javascript:window.model.goToRoot()' if !current_user.is_guest
    if params.has_key? :collection_id
      add_breadcrumb collection.name, 'javascript:window.model.exitSite()'
      if params.has_key? :site_id
        add_breadcrumb params[:site_name], '#'
      end
    end
    render :layout => false
  end

  def new
    add_breadcrumb "Collections", collections_path
    add_breadcrumb "Create new collection", nil
  end

  def create
    if current_user.create_collection collection
      current_user.collection_count += 1
      current_user.update_successful_outcome_status
      current_user.save!
      redirect_to collection_path(collection), notice: "Collection #{collection.name} created"
    else
      render :new
    end
  end

  def update
    if collection.update_attributes params[:collection]

      if collection.public
        guest_user = if ((User.find_by_email 'guest@resourcemap.org') != nil)
          User.find_by_email 'guest@resourcemap.org' 
        else
          User.create!(email: 'guest@resourcemap.org', password: 'guest_resourcemap', is_guest: true)
        end
        guest_user.register_guest_membership(collection.id)
      end

      collection.recreate_index
      redirect_to collection_settings_path(collection), notice: "Collection #{collection.name} updated"
    else
      render :settings
    end
  end

  def show
    @snapshot = Snapshot.new
    add_breadcrumb "Properties", '#'
    respond_to do |format|
      format.html
      format.json { render json: collection }
    end
  end

  def members
    add_breadcrumb "Members", collection_members_path(collection)
  end

  def reminders
    add_breadcrumb "Reminders", collection_reminders_path(collection)
  end

  def settings
    add_breadcrumb "Settings", collection_settings_path(collection)
  end

  def quotas
    add_breadcrumb "Quotas", collection_settings_path(collection)
  end

  def destroy
    if params[:only_sites]
      collection.delete_sites_and_activities
      redirect_to collection_path(collection), notice: "Collection #{collection.name}'s sites deleted"
    else
      collection.destroy
      redirect_to collections_path, notice: "Collection #{collection.name} deleted"
    end
  end

  def csv_template
    send_data collection.csv_template, type: 'text/csv', filename: "collection_sites_template.csv"
  end

  def upload_csv
    collection.import_csv current_user, params[:file].read
    redirect_to collections_path
  end

  def create_snapshot
    @snapshot = Snapshot.create(date: Time.now, name: params[:snapshot][:name], collection: collection)
    if @snapshot.valid?
      redirect_to collection_path(collection), notice: "Snapshot #{params[:name]} created"
    else
      flash.now[:error] = "Snapshot could not be created"
      render :show
    end
  end

  def unload_current_snapshot
    current_snapshot && current_snapshot.user_snapshots.where(user_id: current_user.id).first.destroy

    respond_to do |format|
      format.html {
        flash[:notice] = "Snapshot #{current_snapshot.name} unloaded" if current_snapshot
        redirect_to  collection_path(collection) }
      format.json { render json: :ok }
    end
  end

  def load_snapshot
    snp_to_load = collection.snapshots.where(name: params[:name]).first
    if snp_to_load.user_snapshots.create user: current_user
      redirect_to collection_path(collection), notice: "Snapshot #{params[:name]} loaded"
    end

  end

  def max_value_of_property
    render json: collection.max_value_of_property(params[:property])
  end

  def sites_by_term
    if current_snapshot
      search = collection.new_search snapshot_id: current_snapshot.id, current_user_id: current_user.id
    else
      search = collection.new_search current_user_id: current_user.id
    end

    search.full_text_search params[:term] if params[:term]
    search.select_fields(['id', 'name'])

    search.apply_queries

    results = search.results.map{ |item| item["fields"]}

    results.each do |item|
      item[:value] = item["name"]
    end

    render json: results
  end

  def search

    if current_snapshot
      search = collection.new_search snapshot_id: current_snapshot.id, current_user_id: current_user.id
    else
      search = collection.new_search current_user_id: current_user.id
    end
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search]
    search.offset params[:offset]
    search.limit params[:limit]
    search.sort params[:sort], params[:sort_direction] != 'desc' if params[:sort]
    search.hierarchy params[:hierarchy_code], params[:hierarchy_value] if params[:hierarchy_code]
    search.location_missing if params[:location_missing].present?
    search.where params.except(:action, :controller, :format, :id, :collection_id, :updated_since, :search, :limit, :offset, :sort, :sort_direction, :hierarchy_code, :hierarchy_value, :location_missing)

    search.apply_queries

    results = search.results.map do |result|
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
    render json: results
  end

  def decode_hierarchy_csv
    @hierarchy = collection.decode_hierarchy_csv(params[:file].read)
    @hierarchy_errors = CollectionsController.generate_error_description_list(@hierarchy)
    render layout: false
  end

  def self.generate_error_description_list(hierarchy_csv)
    hierarchy_errors = []
    hierarchy_csv.each do |item|
      message = ""

      if item[:error]
        message << "Error: #{item[:error]}"
        message << " " + item[:error_description] if item[:error_description]
        message << " in line #{item[:order]}." if item[:order]
      end

      hierarchy_errors << message if !message.blank?
    end
    hierarchy_errors.join("<br/>").to_s
  end

  def recreate_index
    render json: collection.recreate_index
  end

  def register_gateways
    collection.channels = Channel.find params["gateways"]
    render json: collection.as_json
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
    ms = collection.messages.where("is_send = true and created_at between ? and ?", start_date, Time.now)
    render json: {status: 200, remain_quota: collection.quota, sended_message: ms.length }
  end
end
