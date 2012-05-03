module Api::JsonHelper
  include Api::TireHelper

  def collection_json(collection, results)
    parents = parents_as_hash results

    p results

    obj = {}
    obj[:name] = collection.name
    obj[:previousPage] = url_for(params.merge page: results.previous_page, only_path: false) if results.previous_page
    obj[:nextPage] = url_for(params.merge page: results.next_page, only_path: false) if results.next_page
    obj[:count] = results.total
    obj[:totalPages] = results.total_pages
    obj[:sites] = results.map {|result| site_item_json result, parents}
    obj
  end

  def site_item_json(result, parents = nil)
    source = result['_source']
    parents ||= parents_as_hash([result])

    obj = {}
    obj[:id] = source['id']
    obj[:name] = source['name']
    obj[:createdAt] = Site.parse_date(source['created_at'])
    obj[:updatedAt] = Site.parse_date(source['updated_at'])

    if source['location']
      obj[:lat] = source['location']['lat']
      obj[:long] = source['location']['lon']
    end

    obj[:properties] = source['properties']

    obj[:groups] = Array(source['parent_ids']).map do |parent_id|
      parent = parents[parent_id]
      {level: parent.level, id: parent.id, name: parent.name}
    end

    obj
  end
end
