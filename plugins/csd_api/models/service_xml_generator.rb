class ServiceXmlGenerator
  def initialize(collection)
    @service_mapping = ServiceMapping.new collection
  end

  def generate_service_xml(xml, service)
    service_properties = service["_source"]["properties"]

    xml.tag!("service", "oid" => service_properties[@service_mapping.oid.code]) do
      generate_coded_types(xml, service_properties)
      generate_record(xml, service)
    end

    xml
  end

  def generate_coded_types(xml, service_properties)
    @service_mapping.coded_type_fields.each do |f|
      xml.tag!("codedType", "code" => service_properties[f.code], "codingSchema" => f.metadata_value_for("codingSchema")) do
        xml.text!(f.human_value_by_option_code(service_properties[f.code]))
      end
    end
  end

  def generate_record(xml, service)
    status = service["_source"]["properties"][@service_mapping.status.code]

    status = "Inactive" if status.nil?
      
    xml.tag!("record", 
      "created" => service["_source"]["created_at"].to_datetime.iso8601, 
      "updated" => service["_source"]["updated_at"].to_datetime.iso8601, 
      "status" => status,
      "sourceDirectory" => "http://#{Settings.host}")
    
    xml
  end
end
