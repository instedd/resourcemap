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

    end

    def generate_facility_xml(xml, facility)
      xml.tag!("facility") do
        xml.tag!("oid", generate_oid(facility))

        facility_properties = facility["_source"]["properties"]

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
      end
      xml
    end

    private

    def generate_contact_points(xml, facility_properties)
      @contact_point_fields_by_type.each do |contact_points_by_type|

        contact_point_fields = contact_points_by_type[1]
        xml.tag!("contactPoint") do
          contact_point_fields.each do |contact_point_element|
            element = contact_point_element.metadata["CSDContactData"] || ""
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
              schema = coded_type_field_for_this_contact.metadata["OptionList"] || ""
              xml.tag!("codingSchema", schema)
            end

          end
        end
      end
    end

    def generate_addresses(xml, facility_properties)
      @address_fields_by_type.each do |address_fields_for_type|
        address_type = address_fields_for_type[0]
        address_fields = address_fields_for_type[1]
        xml.tag!("address", {"type" => address_type}) do

          address_fields.each do |address_field|
            value = facility_properties[address_field.code] || ""
            # TODO: move this to a field's method
            component = address_field.metadata["CSDComponent"] || ""
            xml.tag!("addressLine", {"component" => component}) do
              xml.text!(value)
            end
          end
        end
      end
    end

    def generate_other_names(xml, facility_properties)
      @other_name_fields.each do |other_name_field|
        xml.tag!("otherName") do
          value = facility_properties[other_name_field.code] || ""
          xml.tag!("commonName", value)
          # TODO: move this to a field's method
          language = other_name_field.metadata["CSDLanguage"] || ""
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
          schema = facility_type_field.metadata["OptionList"] || ""
          xml.tag!("codingSchema", schema)
        end
      end
      xml
    end

    def generate_oid(facility)
      # TODO: include as a user-defined collection's metadata
      parent_id = "309768652999692686176651983274504471835"

      # TODO: calculate country from lat-long and obtain the code??
      # 646 is rwanda, hardcoded for the momemnt
      country_code = "646"

      facility_in_decimal = facility["_source"]["uuid"].delete("-").hex
      "2.25.#{parent_id}.#{country_code}.5.#{facility_in_decimal}"
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
