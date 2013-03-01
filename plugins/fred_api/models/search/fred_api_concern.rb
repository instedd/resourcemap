module Search::FredApiConcern
  # Returns the results from ElasticSearch but with codes as keys and codes as
  # values (when applicable).
  def fred_api_results
    visible_fields = @collection.visible_fields_for(@current_user, snapshot_id: @snapshot_id)

    fields_by_es_code = visible_fields.index_by &:es_code

    items = results()

    items.each do |item|
      properties = item['_source']['properties']
      item['_source']['identifiers'] = []
      item['_source']['properties'] = {}

      properties.each_pair do |es_code, value|
        field = fields_by_es_code[es_code]
        if field
          if field.identifier?
            item['_source']['identifiers'] << {:agency => field.agency, :context => field.context , :id => value}
          end
          item['_source']['properties'][field.code] = field.fred_api_value(value)
        end
      end
    end

    items
  end

  def identifier_id(identifier_value)
    identifiers_proc = Proc.new {@collection.fields.find_all{|f|f.identifier?}.map{|i| i.es_code }}
    query_identifier(identifiers_proc, identifier_value)
  end

  def identifier_context_and_id(context_value, identifier_value)
    identifiers_proc = Proc.new { @collection.fields.find_all{|f|f.identifier? && f.context == context_value}.map{|i| i.es_code }}
    query_identifier(identifiers_proc, identifier_value)
  end

  def identifier_context_agency_and_id(context_value, agency_value, identifier_value)
    identifiers_proc = Proc.new { @collection.fields.find_all{|f|f.identifier? && f.agency == agency_value && f.context == context_value}.map{|i| i.es_code }}
    query_identifier(identifiers_proc, identifier_value)
  end

  def identifier_agency_and_id(agency_value, identifier_value)
    identifiers_proc = Proc.new { @collection.fields.find_all{|f|f.identifier? && f.agency == agency_value}.map{|i| i.es_code }}
    query_identifier(identifiers_proc, identifier_value)
  end

  def query_identifier(identifiers_proc, identifier_value)
    identifiers = identifiers_proc.call()
    if identifiers.empty?
      # there is no identifiers that satisfy the condition => the result should be an empty list
      @search.filter :limit, {:value => 0}
    else
      terms = identifiers.map{ |id_es_code| {:terms => { id_es_code => [identifier_value] }} }
      @search.filter :or, terms
    end
    self
  end
end