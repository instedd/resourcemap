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
        codes.push append_star_unless_numeric(text)
        "(#{codes.join " OR "})"
      else
        append_star_unless_numeric(text)
      end
    end

    private

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
