class CollectionsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, :only => :destroy
  before_filter :show_collections_breadcrumb, :only => [:index, :new]
  before_filter :show_collection_breadcrumb, :except => [:index, :new, :create]

  def index
    respond_to do |format|
      format.html
      format.json { render json: collections.all }
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
    collection.destroy

    redirect_to collections_path, notice: "Collection #{collection.name} deleted"
  end

  def csv_template
    send_data collection.csv_template, type: 'text/csv', filename: "collection_sites_template.csv"
  end

  def upload_csv
    collection.import_csv current_user, params[:file].read
    redirect_to collections_path
  end

  def max_value_of_property
    render json: collection.max_value_of_property(params[:property])
  end

  def bulk_update_upload_csv
    BulkUpdate.import current_user, collection, params[:file].read
    redirect_to collection_bulk_update_adjustments_path(collection)
  rescue => ex
    redirect_to collection_bulk_update_path(collection), :notice => "The file was not a valid CSV file"
  end

  def bulk_update
    add_breadcrumb "Import wizard", collection_bulk_update_path(collection)
  end

  def bulk_update_adjustments
    add_breadcrumb "Import wizard", collection_bulk_update_path(collection)
  end

  def bulk_update_sample
    render json: BulkUpdate.sample(current_user, collection)
  end

  def bulk_update_execute
    BulkUpdate.execute(current_user, collection, params[:columns].values)
    render :json => :ok
  end

  def search
    search = collection.new_search
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search]
    search.offset params[:offset]
    search.limit params[:limit]
    search.sort params[:sort], params[:sort_direction] != 'desc' if params[:sort]
    search.hierarchy params[:hierarchy_code], params[:hierarchy_value] if params[:hierarchy_code]
    search.where params.except(:action, :controller, :format, :id, :collection_id, :updated_since, :search, :limit, :offset, :sort, :sort_direction, :hierarchy_code, :hierarchy_value)
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
