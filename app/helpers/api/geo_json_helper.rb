module Api::GeoJsonHelper
  def collection_geo_json(collection, results)
    parents = parents_as_hash results

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
    features[:features] = results.map { |result| site_item_geo_json result, parents }

    root
  end

  def site_item_geo_json(result, parents = nil)
    source = result['_source']
    parents ||= parents_as_hash([result])

    obj = {}
    obj[:type] = 'Feature'
    obj[:geometry] = {type: 'Point', coordinates: [source['location']['lon'], source['location']['lat']]}
    obj[:id] = source['id']
    obj[:properties] = (props = {})

    props[:name] = source['name']
    props[:createdAt] = Site.parse_date(source['created_at'])
    props[:updatedAt] = Site.parse_date(source['updated_at'])
    props[:properties] = source['properties']
    props[:groups] = Array(source['parent_ids']).map do |parent_id|
      parent = parents[parent_id]
      {level: parent.level, id: parent.id, name: parent.name}
    end

    obj
  end
end

