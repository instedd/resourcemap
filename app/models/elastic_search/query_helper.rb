module ElasticSearch::QueryHelper
  class << self
    # Returns a full text search query over the given collection, additionaly
    # specifying which fields to use (will use the collection's fields if not specified).
    #
    # For example, if there's a select one field with code "foo" which has an option
    # with code "bar" and label "baz", when searching for "baz" the generated query
    # will be:
    #
    #   foo:"bar" OR baz*
    #
    # because baz is the label of an option we want to look for, and also the text
    # baz might appear somewhere else.
    #
    # If no field label would have matched, baz* would be the returned string.
    #
    # Addionally, range queries (as "greater than") are apprended to the given tire_search.
    #
    # Can return nil if no condition was generated except comparison of field values.
    def full_text_search(text, tire_search, collection, fields = nil)
      search_hash = SearchParser.new text

      conditions = []

      if text = search_hash.search
        ids = search_value_ids search_hash.search, collection, fields

        if ids.present?
          ids = ids.map { |k, v| %Q(#{k}:"#{v}") }
          ids.push append_star(search_hash.search)
          conditions.push "(#{ids.join " OR "})"
        else
          conditions.push append_star(search_hash.search)
        end
      end

      search_hash.each do |key, value|

        # Check that the field exists indeed in the collection,
        # but only when not searching for name and id
        if key.downcase == 'id' || key.downcase == 'name'
          op = '='
        else
          field = collection.fields.find { |x| x.code == key || x.name == key}
          next unless field

          key = field.es_code
          op, value = SearchParser.get_op_and_val value

          # Check if the user is searching a label instead of the code
          id = search_value_id field, /#{value}/i
          value = id if id
        end

        case op
        when '='
          tire_search.filter :term, key => value
        when '<'
          tire_search.filter :range, key => {lt: value}
        when '<='
          tire_search.filter :range, key => {lte: value}
        when '>'
          tire_search.filter :range, key => {gt: value}
        when '>='
          tire_search.filter :range, key => {gte: value}
        end
      end

      conditions.length > 0 ? (conditions.join " AND ") : nil
    end

    private

    # Searches value ids from their labels on this collections' fields,
    # or in the given fields.
    # Returns a hash of matching field codes and the ids. For example:
    # {:field_es_code => :option_id}
    def search_value_ids(text, collection, fields_to_search = nil)
      fields_to_search ||= collection.fields.all
      fields_to_search = fields_to_search.select &:select_kind?

      codes = {}
      regex = /#{text}/i
      fields_to_search.each do |field|
        option_id = search_value_id field, regex
        codes[field.es_code] = option_id if option_id
      end
      codes
    end

    def search_value_id(field, regex)
      return nil unless field.config && field.config['options']

      field.config['options'].each do |option|
        if option['code'] =~ regex || option['label'] =~ regex
          return option['id']
        end
      end
      nil
    end

    def append_star(text)
     # When searching for a number, like 8, we don't want to search 8*:
     # that is, we don't want to search prefixes, we want to search an exact number.
     # That's why we don't append a start.
      if text.integer?
        text
      else
        # Lucene doesn't support searching for "foo ba*":
        # http://wiki.apache.org/lucene-java/LuceneFAQ#Can_I_combine_wildcard_and_phrase_search.2C_e.g._.22foo_ba.2A.22.3F
        #
        # So our approach here is: if just one word is looked for, we use a star, no quotes.
        # Otherwise, we use quotes and no star.

        if text =~ /\s/
          %Q("#{text}")
        else
          # We do want to search prefixes for location values. This types of values comes as single words.
          "#{text}*"
        end
      end
    end
  end
end
