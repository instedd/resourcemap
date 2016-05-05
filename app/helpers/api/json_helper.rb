require 'new_relic/agent/method_tracer'

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

  include ::NewRelic::Agent::MethodTracer
  add_method_tracer :collection_json, 'Custom/JsonHelper/collection_json'
end
