module FredApi::JsonHelper

  def fred_facility_format(result)
    source = result['_source']

    obj = {}
    obj[:id] = source['id']
    obj[:name] = source['name']

    obj[:createdAt] = format_date_to_iso_string(source['created_at'])
    obj[:updatedAt] = format_date_to_iso_string(source['updated_at'])

    if source['location']
      obj[:coordinates] = [source['location']['lon'], source['location']['lat']]
    end

    # ResourceMap does not implement logical deletion yet. Thus all facilities are active.
    obj[:active] = true

    obj[:url] = url_for(:controller => 'fred_api', :action => 'show_facility',:format => :json, :id => source['id'])

    obj[:properties] = source['properties']

    obj
  end

  private

  def format_date_to_iso_string(rails_format_date_sting)
    date = Site.parse_date(rails_format_date_sting)
    Site.format_date_iso_string(date)
  end
end