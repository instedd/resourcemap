require 'new_relic/agent/method_tracer'

module Api::JsonHelper
  def collection_json(collection, results, user, options = {})
    obj = {}
    obj[:name] = collection.name
    obj[:previousPage] = url_for(params.merge page: results.previous_page, only_path: false) if results.previous_page
    obj[:nextPage] = url_for(params.merge page: results.next_page, only_path: false) if results.next_page
    obj[:count] = results.total
    obj[:totalPages] = results.total_pages
    obj[:sites] = process_labels(collection, results, user, options[:human])
    obj
  end

  def site_item_json(result, human = false, fields = [])
    source = result['_source']

    obj = {}
    obj[:id] = source['id']
    obj[:name] = source['name']
    obj[:createdAt] = Site.parse_time(source['created_at'])
    obj[:updatedAt] = Site.parse_time(source['updated_at'])

    if source['deleted_at']
      obj[:deletedAt] = Site.parse_time(source['deleted_at'])
    end

    if source['location']
      obj[:lat] = source['location']['lat']
      obj[:long] = source['location']['lon']
    end

    obj[:properties] = {}
    if human
      source['properties'].each do |code, value|
        field = fields.find { |f| f.code == code }

        self.trace_execution_scoped(["Custom/JsonHelper/site_item_json/#{field.kind}"]) do
          obj[:properties][code] = if field.is_a?(Field::HierarchyField)
            field.human_value(value) # this case is for optimization only.
            # Field::HierarchyField#csv_values ends up building the whole ascendent trace
            # for each element.
            # Field::SelectOneField#human_value can't be used instead of #csv_values here
            # since the +value+ has the code but not the id of the selected option.
          else
            field.csv_values(value, human).first
          end
        end
      end
    else
      obj[:properties] = source['properties']
    end

    obj
  end

  include ::NewRelic::Agent::MethodTracer
  add_method_tracer :site_item_json, 'Custom/JsonHelper/site_item_json'

  def process_labels(collection, results, user, human = false)
    fields = []
    if human
      fields = collection.visible_fields_for(user)
      fields.each(&:cache_for_read)
    end
    results.map {|result| site_item_json result, human, fields}
  end
end
