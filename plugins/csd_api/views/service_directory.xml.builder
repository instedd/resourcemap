xml = Builder::XmlMarkup.new(:encoding => 'utf-8', :escape => false)
services_directory_xml_for_get_modifications xml, @services, @request_id, @collection
