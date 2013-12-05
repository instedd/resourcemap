class SitesController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :search], :unless => Proc.new { collection && collection.public }
  before_filter :authenticate_collection_admin!, :only => :update

  authorize_resource :only => [:index, :search], :decent_exposure => true

  expose(:sites) {if !current_user_snapshot.at_present? && collection then collection.site_histories.at_date(current_user_snapshot.snapshot.date) else collection.sites end}
  expose(:site) { Site.find(params[:site_id] || params[:id]) }

  def index
    search = new_search

    search.name_start_with params[:name] if params[:name].present?
    search.offset params[:offset]
    search.limit params[:limit]

    results = search.ui_results
    render_json({ sites: results[:sites].map { |x| x['_source'] }, total_count: results[:total_count] })
  end

  def show
    search = new_search

    search.id params[:id]
    # If site does not exists, return empty object
    result = search.ui_results[:sites].first['_source'] rescue {}
    render_json result
  end

  def create
    site_params = JSON.parse params[:site]

    site = collection.sites.new(user: current_user)

    validate_and_process_parameters(site, site_params)

    site.assign_default_values_for_create

    if site.valid?
      site.save!
      current_user.site_count += 1
      current_user.update_successful_outcome_status
      current_user.save!
      render_json site, :layout => false
    else
      render_json site.errors.messages, status: :unprocessable_entity, :layout => false
    end
  end

  # This action updates the entire entity.
  # It perform a full update, erasing the values for the fields that are not present in the request
  # It is only accessible by admins: there are no permission validations in the code
  def update
    site_params = JSON.parse params[:site]
    site.user = current_user
    site.properties_will_change!
    site.attributes = decode_from_ui(site_params)

    if site.valid?
      site.save!
      render_json(site, :layout => false)
    else
      render_json(site.errors.messages, status: :unprocessable_entity, :layout => false)
    end
  end

  # This action modifies only the fields that are present in the request.
  def partial_update
    site_params = JSON.parse params[:site]
    site.user = current_user

    validate_and_process_parameters(site, site_params)

    if site.valid?
      site.save!
      render_json(site, :layout => false)
    else
      render_json(site.errors.messages, status: :unprocessable_entity, :layout => false)
    end
  end

  def update_property
    field = site.collection.fields.where_es_code_is params[:es_code]

    #Pending: Check custom site permission
    return head :forbidden unless can?(:update_site_property, field)

    site.user = current_user
    site.properties_will_change!
    site.assign_default_values_for_update
    site.properties[params[:es_code]] = field.decode_from_ui(params[:value])
    if site.valid?
      site.save!
      render_json(site, :status => 200, :layout => false)
    else
      error_message = site.errors[:properties][0][params[:es_code]]
      render_json({:error_message => error_message}, status: :unprocessable_entity, :layout => false)
    end
  end

  def search
    zoom = params[:z].to_i

    search = MapSearch.new params[:collection_ids], user: current_user

    search.zoom = zoom
    search.bounds = params if zoom >= 2
    search.exclude_id params[:exclude_id].to_i if params[:exclude_id].present?
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search].present?
    search.location_missing if params[:location_missing].present?
    if params[:selected_hierarchies].present?
      search.selected_hierarchy params[:hierarchy_code], params[:selected_hierarchies]
    end
    search.where params.except(:action, :controller, :format, :n, :s, :e, :w, :z, :collection_ids, :exclude_id, :updated_since, :search, :location_missing, :hierarchy_code, :selected_hierarchies)

    search.apply_queries
    render_json search.results
  end

  def destroy
    site.user = current_user
    site.destroy
    render_json site
  end

  private

  def decode_from_ui(parameters)
    fields = collection.fields.index_by(&:es_code)
    decoded_properties = {}
    site_properties = parameters.delete "properties"
    site_properties ||= {}
    site_properties.each_pair do |es_code, value|
      decoded_properties[es_code] = fields[es_code].decode_from_ui(value)
    end

    parameters["properties"] = decoded_properties
    parameters
  end

  # TODO: Integrate with cancan
  def validate_and_process_parameters(site, site_params)
    user_membership = current_user.membership_in(collection)

    if site_params.has_key?("name")
      if user_membership.can_update?("name")
        site.name = site_params["name"]
      else
        raise CanCan::AccessDenied.new("Not authorized to update Site name", :update, Site)
      end
    end

    if site_params.has_key?("lat")
      if user_membership.can_update?("location")
        site.lat = site_params["lat"]
      else
        raise CanCan::AccessDenied.new("Not authorized to update Site location", :update, Site)
      end
    end

    if site_params.has_key?("lng")
      if user_membership.can_update?("location")
        site.lng = site_params["lng"]
      else
        raise CanCan::AccessDenied.new("Not authorized to update Site location", :update, Site)
      end
    end

    if site_params.has_key?("properties")
      fields = collection.fields.index_by(&:es_code)

      site_params["properties"].each_pair do |es_code, value|

        #Next if there is no changes in the property
        next if value == site.properties[es_code]

        field = fields[es_code]
        if field && can?(:update_site_property, field)
          site.properties[es_code] = field.decode_from_ui(value)
        else
          raise CanCan::AccessDenied.new("Not authorized to update Site property with code #{es_code}", :update, Site)
        end
      end
    end

    # after, so if the user update the whole site
    # the auto_reset is reseted
    if site.changed?
      site.assign_default_values_for_update
    end
  end

end
