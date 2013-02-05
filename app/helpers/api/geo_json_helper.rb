module Api::GeoJsonHelper
  def collection_geo_json(collection, results)
    root = {}
    root[:type] = 'Feature'
    root[:geometry] = nil
    root[:properties] = (props = {features: (features = {})})

    props[:name] = collection.name
    props[:previousPage] = url_for(params.merge page: results.previous_page, only_path: false) if results.previous_page
    props[:nextPage] = url_for(params.merge page: results.next_page, only_path: false) if results.next_page
    props[:count] = results.total
    props[:totalPages] = results.total_pages

    features[:type] = 'FeatureCollection'
    features[:features] = results.map { |result| site_item_geo_json result }

    root
  end

  def site_item_geo_json(result)
    source = result['_source']

    obj = {}
    obj[:type] = 'Feature'
    obj[:geometry] = {type: 'Point', coordinates: [source['location']['lon'], source['location']['lat']]}
    obj[:id] = source['id']
    obj[:properties] = (props = {})

    props[:name] = source['name']
    props[:createdAt] = Site.parse_time(source['created_at'])
    props[:updatedAt] = Site.parse_time(source['updated_at'])
    props[:properties] = source['properties']

    obj
  end
end

