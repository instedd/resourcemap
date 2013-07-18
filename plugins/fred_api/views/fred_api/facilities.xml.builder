xml.instruct!
xml.facilities "xmlns" => "http://facilityregistry.org/api/v1", "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation" => "http://facilityregistry.org/api/v1 fred.xsd" do
  @fred_json_facilities.each do |f|
    xml.facility do
      xml.name f[:name]
      xml.href f[:href].sub('.json', '.xml')
      xml.uuid f[:uuid]
      xml.active f[:active]
      xml.createdAt f[:createdAt]
      xml.updatedAt f[:updatedAt]

      if f[:coordinates]
        xml.coordinates do
          xml.lat f[:coordinates][1]
          xml.long f[:coordinates][0]
        end
      end

      xml.identifiers do
        f[:identifiers].each do
          xml.id f[:id]
          xml.agency f[:agency]
          xml.context f[:context]
        end
      end

      xml.properties do
        f[:properties].each_key do |key|
          xml.tag! key, f[:properties][key]
        end
      end
    end
  end
end
