class Field::SiteField < Field
  def value_type_description
    "site ids"
  end

  def error_description_for_invalid_values
    "don't match any existing site id in this collection"
  end

	def apply_format_save_validation(value, use_codes_instead_of_es_codes, collection)
		value.blank? ? nil : check_site_exists(value, collection)
	end

	private

	def check_site_exists(site_id, collection)
    site_ids = collection.sites.map{|s| s.id.to_s}

    if !site_ids.include? site_id.to_s
      raise "Non-existent site-id in field #{code}"
    end
    site_id
  end

end