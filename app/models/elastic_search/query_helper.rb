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
    def full_text_search(text, collection, fields = nil)
      codes = collection.search_value_codes text, fields

      if codes.present?
        codes = codes.map { |k, v| %Q(#{Site.encode_elastic_search_keyword(k)}:"#{v}") }
        codes.push "#{text}*"
        "(#{codes.join " OR "})"
      else
        "#{text}*"
      end
    end
  end
end
