xml = Builder::XmlMarkup.new(:encoding => 'utf-8', :escape => false)
facilities_directory_xml_for_get_modifications xml, @facilities, @request_id, @collection
