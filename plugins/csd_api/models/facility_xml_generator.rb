  class FacilityXmlGenerator
    def initialize(collection)
       # Used to generate 'otherId's
      @identifier_fields = collection.identifier_fields

      # Used to generate 'facilityTypes'
      @facility_type_fields = collection.facility_type_fields

      # Used to generate 'otherNames'
      @other_name_fields = collection.facility_other_name_fields

      # Used to generate 'address'
      @address_fields_by_type = collection.facility_address_fields

      # Used to generate 'contactPoint'
      @contact_point_fields_by_type = collection.facility_contact_point_fields
      @coded_type_for_contact_point_fields_by_type = collection.coded_type_for_contact_point_fields

      # Used to generate 'language'
      @language_fields = collection.facility_language_fields

      # Used to generate 'status' required
      @status_field = collection.facility_status_field

      @oid_field = collection.csd_oid_field
    end

    def generate_facility_xml(xml, facility)
      facility_properties = facility["_source"]["properties"]

      xml.tag!("facility", "oid" => generate_oid(facility, facility_properties)) do
        generate_identifiers(xml, facility_properties)

        generate_facility_types(xml, facility_properties)

        xml.tag!("primaryName", facility["_source"]["name"])

        generate_other_names(xml, facility_properties)

        xml.tag!("geocode") do
          xml.tag!("latitude", facility["_source"]["location"]["lat"])
          xml.tag!("longitude", facility["_source"]["location"]["lon"])
          xml.tag!("coordinateSystem", "WGS-84")
        end

        generate_addresses(xml, facility_properties)

        generate_contact_points(xml, facility_properties)

        generate_languages(xml, facility_properties)

        generate_record(xml, facility)
      end

      xml
    end

    def has_entry(metadata, metadata_key)
      metadata.values.find{|element| element["key"] == metadata_key}
    end

    def entry(metadata, metadata_key)
      if has_entry(metadata, metadata_key)
        metadata_entry = metadata.values.find{|element| element["key"] == metadata_key}
        metadata_entry["value"]
      end
    end

    def generate_record(xml, facility)
      xml.tag!("record") do
        xml.tag!("created", facility["_source"]["created_at"].to_datetime.iso8601)
        xml.tag!("updated", facility["_source"]["updated_at"].to_datetime.iso8601)
        # TODO: This field is required in the xsd. We need to discuss if a 'default' value is a good option here.
        status = facility["_source"]["properties"][@status_field.code] rescue "active"
        status_value = status ? "active" : "inactive"
        xml.tag!("status", status_value)
        xml.tag!("sourceDirectory", "http://#{Settings.host}")
      end
      xml
    end

    def generate_languages(xml, facility_properties)
      @language_fields.each do |language_field|
        xml.tag!("language") do
          value = facility_properties[language_field.code] || ""
          xml.tag!("code", value)
          # TODO: move this to a field's method
          schema = entry(language_field.metadata, "OptionList") || ""
          xml.tag!("codingSchema", schema)
        end
      end
      xml
    end

    def generate_contact_points(xml, facility_properties)
      @contact_point_fields_by_type.each do |contact_points_by_type|

        contact_point_fields = contact_points_by_type[1]
        xml.tag!("contactPoint") do
          contact_point_fields.each do |contact_point_element|
            element = entry(contact_point_element.metadata, "CSDContactData") || ""
            value = facility_properties[contact_point_element.code] || ""
            xml.tag!(element.downcase, value)
          end

          contact_point_code = contact_points_by_type[0]

          if @coded_type_for_contact_point_fields_by_type[contact_point_code]
            coded_type_field_for_this_contact = @coded_type_for_contact_point_fields_by_type[contact_point_code][0]
            xml.tag!("codedType") do
              value = facility_properties[coded_type_field_for_this_contact.code] || ""
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

    def generate_addresses(xml, facility_properties)
      @address_fields_by_type.each do |address_fields_for_type|
        address_type = address_fields_for_type[0]
        address_fields = address_fields_for_type[1]
        xml.tag!("address", {"type" => address_type}) do

          address_fields.each do |address_field|
            value = facility_properties[address_field.code] || ""
            # TODO: move this to a field's method
            component = entry(address_field.metadata, "CSDComponent") || ""
            xml.tag!("addressLine", {"component" => component}) do
              xml.text!(value)
            end
          end
        end
      end
      xml
    end

    def generate_other_names(xml, facility_properties)
      @other_name_fields.each do |other_name_field|
        xml.tag!("otherName") do
          value = facility_properties[other_name_field.code] || ""
          xml.tag!("commonName", value)
          # TODO: move this to a field's method
          language = entry(other_name_field.metadata, "CSDLanguage") || ""
          xml.tag!("language", language)
        end
      end
      xml
    end

    def generate_facility_types(xml, facility_properties)
      @facility_type_fields.each do |facility_type_field|
        xml.tag!("codedType") do
          value = facility_properties[facility_type_field.code] || ""
          xml.tag!("code", value)
          # TODO: move this to a field's method
          schema = entry(facility_type_field.metadata, "OptionList") || ""
          xml.tag!("codingSchema", schema)
        end
      end
      xml
    end

    def generate_oid(facility, facility_properties)
      #If there's an explicitly set up OID, use its value as is, otherwise generate 
      #one from the UUID.
      if @oid_field
        facility_properties[@oid_field.code] || ""
      else
        to_oid facility["_source"]["uuid"]
      end
    end

    def to_oid(uuid)
      #These should move to collection level settings
      parent_id = "309768652999692686176651983274504471835"
      country_code = "646"

      "2.25.#{parent_id}.#{country_code}.5.#{uuid.delete("-").hex}"      
    end

    def generate_identifiers(xml, facility_properties)
      @identifier_fields.each do |identifier_field|
        xml.tag!("otherID") do
          value = facility_properties[identifier_field.code] || ""
          xml.tag!("code", value)
          agency = identifier_field.agency
          xml.tag!("assigningAuthorityName", agency)
        end
      end
      xml
    end

  end
