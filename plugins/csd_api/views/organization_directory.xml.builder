xml = Builder::XmlMarkup.new(:encoding => 'utf-8', :escape => false)
organizations_directory_xml_for_get_modifications xml, @organizations, @request_id, @collection
