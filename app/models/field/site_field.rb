class Field::SiteField < Field
  def value_type_description
    "site ids"
  end

  def error_description_for_invalid_values(exception)
    "don't match any existing site id in this collection"
  end

  def valid_value?(site_id, site=nil)
    check_site_exists(site_id)
  end


	private

	def check_site_exists(site_id)
    site_ids = collection.sites.map{|s| s.id.to_s}

    if !site_ids.include? site_id.to_s
      raise "Non-existent site-id in field #{code}"
    end
    true
  end

end
