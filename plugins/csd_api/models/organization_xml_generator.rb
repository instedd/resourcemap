class OrganizationXmlGenerator
	def initialize(collection)
    @organization_mapping = OrganizationMapping.new collection
  end

  def generate_organization_xml(xml, organization)
    organization_properties = organization["_source"]["properties"]

    xml.tag!("organization", "oid" => organization_properties[@organization_mapping.oid.code]) do
      generate_coded_types(xml, organization_properties)

      xml.tag!("primaryName", organization["_source"]["name"])

      generate_addresses(xml, organization_properties)

      p 'contacts'
      generate_contacts(xml, organization_properties)

      p 'languages'
      generate_languages(xml, organization_properties)

      p 'contact points'
      generate_contact_points(xml, organization_properties)

      p 'records'
      generate_record(xml, organization)
    end

    xml
  end

  def generate_contact_points(xml, organization_properties)
  	coded_type_for_contact_point_fields_by_type = @organization_mapping.coded_type_for_contact_point_fields_by_type

    @organization_mapping.contact_point_fields_by_type.each do |contact_points_by_type|
      contact_point_fields = contact_points_by_type[1]
      xml.tag!("contactPoint") do
        contact_point_fields.each do |contact_point_element|
          element = entry(contact_point_element.metadata, "CSDContactData") || ""
          value = organization_properties[contact_point_element.code] || ""
          xml.tag!(element.downcase, value)
        end

        contact_point_code = contact_points_by_type[0]

        if coded_type_for_contact_point_fields_by_type[contact_point_code]
          coded_type_field_for_this_contact = coded_type_for_contact_point_fields_by_type[contact_point_code][0]
          xml.tag!("codedType") do
            value = organization_properties[coded_type_field_for_this_contact.code] || ""
            xml.tag!("code", value)
            # TODO: move this to a field's method
            schema = entry(coded_type_field_for_this_contact.metadata, "OptionList") || ""
            xml.tag!("codingSchema", schema)
          end
        end
      end
    end
    xml
  end

  def generate_languages(xml, organization_properties)
    @organization_mapping.languages.each do |language|
    	language_field = language.field
      value = organization_properties[language_field.code] || ""
      schema = language_field.metadata_value_for("codingSchema") || ""
      xml.tag!("language", "code" => value, "codingSchema" => schema) do
        xml.text!(language_field.human_value_by_option_code(value))
      end
    end
    xml
  end

  def generate_contacts(xml, organization_properties)
	  #TODO: this should work automatically given the right object graph
	  @organization_mapping.contacts.each do |contact|
	    p "contact"
	    xml.tag!("contact") do
	      xml.tag!("person") do
	        contact.names.each do |name|
	          p "name"
	          xml.tag!("name") do
	            name.common_names.each do |common_name|
	              p "common name"
	              xml.tag!("commonName", "language" => common_name.language) do
	                xml.text!(organization_properties[common_name.field.code])
	              end                
	            end
	            xml.tag!("forename") do
	              xml.text!(organization_properties[name.forename.code])
	            end
	            xml.tag!("surname") do
	              xml.text!(organization_properties[name.surname.code])
	            end
	          end
	        end

	        contact.addresses.each do |address|
	          p "address"
	          xml.tag!("address") do
	            address.address_lines.each do |address_line|
	              p "address line"
	              xml.tag!("addressLine", "component" => address_line.component) do
	                xml.text!(organization_properties[address_line.field.code] || "")
	              end
	            end
	          end
	        end
	      end
	    end
	  end
  end

  def generate_addresses(xml, organization_properties)
  	@organization_mapping.addresses.each do |address|
      p "address"
      xml.tag!("address") do
        address.address_lines.each do |address_line|
          p "address line"
          xml.tag!("addressLine", "component" => address_line.component) do
            xml.text!(organization_properties[address_line.field.code] || "")
          end
        end
      end
    end
  end

  def generate_coded_types(xml, organization_properties)
    @organization_mapping.coded_type_fields.each do |f|
      xml.tag!("codedType", "code" => organization_properties[f.code], "codingSchema" => f.metadata_value_for("codingSchema")) do
        xml.text!(f.human_value_by_option_code(organization_properties[f.code]))
      end
    end
  end

  def generate_record(xml, organization)
    xml.tag!("record", 
      "created" => organization["_source"]["created_at"].to_datetime.iso8601, 
      "updated" => organization["_source"]["updated_at"].to_datetime.iso8601, 
      "status" => "Active",
      "sourceDirectory" => "http://#{Settings.host}")
    
    xml
  end
end