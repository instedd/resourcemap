module Api::JsonHelper
  def collection_json(collection, results)
    obj = {}
    obj[:name] = collection.name
    obj[:previousPage] = url_for(params.merge page: results.previous_page, only_path: false) if results.previous_page
    obj[:nextPage] = url_for(params.merge page: results.next_page, only_path: false) if results.next_page
    obj[:count] = results.total
    obj[:totalPages] = results.total_pages
    obj[:sites] = results.map { |item| site_item_json(item) }
    obj
  end

  def collections_json(collections, sites_counts)
    collections.each do |collection|
      {
        anonymous_location_permission: collection.anonymous_location_permission,
        anonymous_name_permission: collection.anonymous_name_permission,
        created_at: collection.created_at,
        description: collection.description,
        icon: collection.icon,
        id: collection.id,
        lat: collection.lat,
        lng: collection.lng,
        max_lat: collection.max_lat,
        max_lng: collection.max_lng,
        min_lat: collection.min_lat,
        min_lng: collection.min_lng,
        name: collection.name,
        updated_at:collection.updated_at,
        count: sites_counts[collection.id].to_i,
      }
    end
  end

  def site_item_json(result)
    source = result['_source']

    obj = {}
    obj[:id] = source['id']
    obj[:name] = source['name']
    obj[:createdAt] = Site.parse_time(source['created_at']).as_json
    obj[:updatedAt] = Site.parse_time(source['updated_at']).as_json

    if source['deleted_at']
      obj[:deletedAt] = Site.parse_time(source['deleted_at']).as_json
    end

    if source['location']
      obj[:lat] = source['location']['lat']
      obj[:long] = source['location']['lon']
    end

    obj[:properties] = source['properties']

    obj
  end
end
