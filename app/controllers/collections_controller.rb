class CollectionsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, :only => [:destroy, :create_snapshot]
  before_filter :show_collections_breadcrumb, :only => [:index, :new]
  before_filter :show_collection_breadcrumb, :except => [:index, :new, :create]

  def index
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

  def new
    add_breadcrumb "Create new collection", nil
  end

  def create
    if current_user.create_collection collection
      redirect_to collection_path(collection), notice: "Collection #{collection.name} created"
    else
      render :new
    end
  end

  def update
    if collection.update_attributes params[:collection]
      redirect_to collection_settings_path(collection), notice: "Collection #{collection.name} updated"
    else
      render :settings
    end
  end

  def show
    @snapshot = Snapshot.new
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
      format.html { redirect_to collection_path(collection), notice: "Snapshot #{current_snapshot.name} unloaded" }
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

  def import_wizard_upload_csv
    ImportWizard.import current_user, collection, params[:file].read
    redirect_to collection_import_wizard_adjustments_path(collection)
  rescue => ex
    redirect_to collection_import_wizard_path(collection), :notice => "The file was not a valid CSV file"
  end

  def import_wizard
    add_breadcrumb "Import wizard", collection_import_wizard_path(collection)
  end

  def import_wizard_adjustments
    add_breadcrumb "Import wizard", collection_import_wizard_path(collection)
  end

  def import_wizard_sample
    render json: ImportWizard.sample(current_user, collection)
  end

  def import_wizard_execute
    ImportWizard.execute(current_user, collection, params[:columns].values)
    render :json => :ok
  end

  def search

    if current_snapshot
      search = collection.new_search snapshot_id: current_snapshot.id
    else
      search = collection.new_search
    end
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search]
    search.offset params[:offset]
    search.limit params[:limit]
    search.sort params[:sort], params[:sort_direction] != 'desc' if params[:sort]
    search.hierarchy params[:hierarchy_code], params[:hierarchy_value] if params[:hierarchy_code]
    search.location_missing if params[:location_missing].present?
    search.where params.except(:action, :controller, :format, :id, :collection_id, :updated_since, :search, :limit, :offset, :sort, :sort_direction, :hierarchy_code, :hierarchy_value, :location_missing)

    results = search.results.map do |result|
      source = result['_source']

      obj = {}
      obj[:id] = source['id']
      obj[:name] = source['name']
      obj[:created_at] = Site.parse_date(source['created_at'])
      obj[:updated_at] = Site.parse_date(source['updated_at'])

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
    render layout: false
  end

  def recreate_index
    render json: collection.recreate_index
  end
end
