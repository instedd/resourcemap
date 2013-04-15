class Field::SiteField < Field

	def apply_format_update_validation(value, use_codes_instead_of_es_codes, collection)
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