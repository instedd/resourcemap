xml = Builder::XmlMarkup.new(:encoding => 'utf-8', :escape => false)
facilities_directory_xml xml, @facilities
