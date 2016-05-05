class ElasticSearch::ResultsMapper
  attr_accessor :results

  def initialize(results, options)
    @results = results
    @collection = options.fetch(:collection)
    @current_user = options.fetch(:current_user)
    @snapshot_id = options.fetch(:snapshot_id, nil)
  end

  def visible_fields
    @visible_fields ||= @collection.visible_fields_for(@current_user, snapshot_id: @snapshot_id).tap do |fields|
      fields.each { |field| field.code.freeze; field.cache_for_read }
    end
  end

  def fields_by_es_code
    @fields_by_es_code ||= visible_fields.index_by(&:es_code)
  end

  def for_json(human = false)
    @results.each do |item|
      properties = item['_source']['properties']
      mapped_props = {}

      properties.each_pair do |es_code, value|
        field = fields_by_es_code[es_code]
        if field
          mapped_props[field.code] = if human
                                    field.human_value(value)
                                  else
                                    field.api_value(value)
                                  end
        end
      end
      item['_source']['properties'] = mapped_props
    end
    @results
  end

  def for_csv(human = false)
    @results.each do |item|
      properties = item['_source']['properties']
      mapped_props = {}

      visible_fields.each do |field|
        mapped_props[field.code] = field.csv_values(properties[field.es_code], human)
      end
      item['_source']['properties'] = mapped_props
    end
    @results
  end

  def for_ui
    @results.each do |item|
      item_source = item['_source']
      if item_source['location']
        item_source['lat'] = item_source['location']['lat']
        item_source['lng'] = item_source['location']['lon']
        item_source.delete 'location'
      end
      item_source['created_at'] = Site.parse_time item_source['created_at']
      item_source['updated_at'] = Site.parse_time item_source['updated_at']
      item_source['properties'] = item_source['properties'].select do |es_code, value|
        fields_by_es_code[es_code]
      end
    end
    @results
  end
end
