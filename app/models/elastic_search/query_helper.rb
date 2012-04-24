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
        codes = search_value_codes search_hash.search, collection, fields

        if codes.present?
          codes = codes.map { |k, v| %Q(#{Site.encode_elastic_search_keyword(k)}:"#{v}") }
          codes.push append_star_unless_numeric(search_hash.search)
          conditions.push "(#{codes.join " OR "})"
        else
          conditions.push append_star_unless_numeric(search_hash.search)
        end
      end

      search_hash.each do |key, value|

        # Check that the field exists indeed in the collection,
        # but only when not searching for name and id
        if key.downcase == 'id' || key.downcase == 'name'
          op = '='
        else
          field =  collection.fields.find { |x| x.code == key || x.name == key}
          next unless field

          key = Site.encode_elastic_search_keyword field.code
          op, value = SearchParser.get_op_and_val value

          # Check if the user is searching a label instead of the code
          code = search_value_code field, /#{value}/i
          value = code if code
        end

        case op
        when '='
          conditions.push "#{key}:#{value}"
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

    # Searches value codes from their labels on this collections' fields,
    # or in the given fields.
    # Returns a hash of matching field codes and the codes. For example:
    # {:field_code => :option_code}
    def search_value_codes(text, collection, fields_to_search = nil)
      fields_to_search ||= collection.fields.all
      fields_to_search = fields_to_search.select &:select_kind?

      codes = {}
      regex = /#{text}/i
      fields_to_search.each do |field|
        option_code = search_value_code field, regex
        codes[field.code] = option_code if option_code
      end
      codes
    end

    def search_value_code(field, regex)
      return nil unless field.config && field.config['options']

      field.config['options'].each do |option|
        if option['label'] =~ regex
          return option['code']
        end
      end
      nil
    end

    # When searching for a number, like 8, we don't want to search 8*:
    # that is, we don't want to search prefixes, we want to search an exact number.
    # That's why we don't append a start.
    def append_star_unless_numeric(text)
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
          "#{text}*"
        end
      end
    end
  end
end
