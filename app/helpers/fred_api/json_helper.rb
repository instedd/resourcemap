module FredApi::JsonHelper

  def url_for_facility(id)
    url_for(:controller => 'fred_api', :action => 'show_facility',:format => :json, :id => id)
  end

  def fred_facility_format(result)
    source = result['_source']

    obj = {}
    obj[:id] = source['id'].to_s
    obj[:name] = source['name']

    obj[:createdAt] = format_time_to_iso_string(source['created_at'])
    obj[:updatedAt] = format_time_to_iso_string(source['updated_at'])
    if source['location']
      obj[:coordinates] = [source['location']['lon'], source['location']['lat']]
    end

    # ResourceMap does not implement logical deletion yet. Thus all facilities are active.
    obj[:active] = true

    obj[:url] = url_for_facility(source['id'])

    obj[:properties] = source['properties']

    obj
  end

  private

  def format_time_to_iso_string(es_format_date_sting)
    date = Site.parse_time(es_format_date_sting)
    date.iso8601
  end
end