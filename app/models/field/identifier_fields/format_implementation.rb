
class Field::IdentifierFields::FormatImplementation

  def existing_values
    if @cache_for_read && @existing_values_in_cache
      return @existing_values_in_cache
    end

    search = @field.collection.new_search
    property_code = "properties.#{@field.es_code}"
    search.select_fields(["id",property_code])
    search.unlimited
    search.apply_queries
    existing = search.results.results.map{ |item| item["fields"]}.index_by{|e| e[property_code]}

    if @cache_for_read
      @existing_values_in_cache = existing
    end

    existing
  end


  def cache_for_read
    @cache_for_read = true
  end

  def disable_cache_for_read
    @cache_for_read = false
  end

  def initialize(field)
    @field = field
  end

  def valid_value?(value, existing_site_id)
    if existing_values[value]
      # If the value already exists in the collection, the value will be invalid
      # Unless this is an update to an update an existing site with the same value
      raise "the value already exists in the collection" unless (existing_site_id && (existing_values[value]["id"].to_s == existing_site_id.to_s))    end
    true
  end

  def has_luhn_format?()
    false
  end

  def decode(value)
    value
  end

  def default_value_for_create(collection)
    nil
  end

  def value_hint
    nil
  end

end
