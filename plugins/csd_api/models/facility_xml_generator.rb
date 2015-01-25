class FacilityXmlGenerator
  def initialize(collection)
    @identifier_fields = collection.csd_other_ids

    @facility_type_fields = collection.csd_facility_types

    @other_name_fields = collection.csd_other_names

    @address_fields_by_type = collection.csd_addresses

    @contact_point_fields_by_type = collection.csd_text_contact_points
    @coded_type_for_contact_point_fields_by_type = collection.csd_select_one_contact_points

    @language_fields = collection.csd_languages

    @status_field = collection.csd_status

    @entity_id_field = collection.csd_facility_entity_id

    @coded_type_fields = collection.csd_coded_types

    @contacts = collection.csd_contacts

    @organizations = collection.csd_organizations

    @operating_hours = collection.csd_operating_hours
  end

  def generate_facility_xml(xml, facility)
    facility_properties = facility["_source"]["properties"]

    xml.tag!("facility", "entityID" => generate_entity_id(facility, facility_properties)) do

      generate_other_ids(xml, facility_properties)
      generate_coded_types(xml, facility_properties)

      xml.tag!("primaryName", facility["_source"]["name"])

      generate_other_names(xml, facility_properties)
      generate_addresses(xml, facility_properties)
      generate_contacts(xml, facility_properties)

      xml.tag!("geocode") do
        xml.tag!("latitude", facility["_source"]["location"]["lat"])
        xml.tag!("longitude", facility["_source"]["location"]["lon"])
      end

      generate_languages(xml, facility_properties)
      generate_contact_points(xml, facility_properties)
      generate_organizations(xml, facility_properties)
      generate_operating_hours(xml, facility_properties, @operating_hours)
      generate_record(xml, facility)
    end

    xml
  end

  def operating_hours_tag_has_content?(facility_properties, oh)
    return oh.open_flag && facility_properties[oh.open_flag.code] ||
      oh.day_of_the_week && facility_properties[oh.day_of_the_week.code] ||
      oh.beginning_hour && facility_properties[oh.beginning_hour.code] ||
      oh.ending_hour && facility_properties[oh.ending_hour.code] ||
      oh.begin_effective_date && facility_properties[oh.begin_effective_date.code]
  end

  def generate_operating_hours(xml, facility_properties, operating_hours)
    operating_hours.each do |oh|
      if (operating_hours_tag_has_content?(facility_properties, oh))
        xml.tag!("operatingHours") do
          if oh.open_flag
            xml.tag!("openFlag") do
              xml.text!(facility_properties[oh.open_flag.code] ? "1" : "0")
            end
          end

          if oh.day_of_the_week
            xml.tag!("dayOfTheWeek") do
              xml.text!(facility_properties[oh.day_of_the_week.code].to_s)
            end
          end

          if oh.beginning_hour
            xml.tag!("beginningHour") do
              xml.text!(facility_properties[oh.beginning_hour.code] || "")
            end
          end

          if oh.ending_hour
            xml.tag!("endingHour") do
              xml.text!(facility_properties[oh.ending_hour.code] || "")
            end
          end

          if oh.begin_effective_date
            xml.tag!("beginEffectiveDate") do
              xml.text!(facility_properties[oh.begin_effective_date.code] || "")
            end
          end
        end
      end
    end
  end

  def service_tag_has_content?(facility_properties, service)
    return service.oid && facility_properties[service.oid.code]
  end

  def generate_organizations(xml, facility_properties)
    xml.tag!("organizations") do
      @organizations.each do |org|
        xml.tag!("organization", "entityID" => facility_properties[org.oid.code]) do
          org.services.each do |service|

            if service_tag_has_content?(facility_properties, service)
              xml.tag!("service", "entityID" => facility_properties[service.oid.code]) do
                service.names.each do |name|
                  xml.tag!("name") do
                    xml.tag!("commonName") do
                      xml.text!(facility_properties[name.all_components.first.code] || "")
                    end
                  end
                end

                service.languages.each do |language|
                  if facility_properties[language.field.code]
                    xml.tag!("language", "code" => facility_properties[language.field.code], "codingScheme" => language.coding_schema) do
                      xml.text!(language.field.human_value_by_option_code(facility_properties[language.field.code]))
                    end
                  end
                end

                generate_operating_hours(xml, facility_properties, service.operating_hours)
              end
            end
          end
        end
      end
    end
  end

  def generate_contacts(xml, facility_properties)
    #TODO: this should work automatically given the right object graph
    @contacts.each do |contact|
      xml.tag!("contact") do
        xml.tag!("person") do
          contact.names.each do |name|
            xml.tag!("name") do
              name.common_names.each do |common_name|
                xml.tag!("commonName") do
                  xml.text!(facility_properties[common_name.field.code])
                end
              end
              xml.tag!("forename") do
                xml.text!(facility_properties[name.forename.code])
              end
              xml.tag!("surname") do
                xml.text!(facility_properties[name.surname.code])
              end
            end
          end
          contact.addresses.each do |address|
            xml.tag!("address") do
              address.address_lines.each do |address_line|
                xml.tag!("addressLine", "component" => address_line.component) do
                  xml.text!(facility_properties[address_line.field.code] || "")
                end
              end
            end
          end
        end
      end
    end
  end

  def generate_coded_types(xml, facility_properties)
    @coded_type_fields.each do |f|
      xml.tag!("codedType", "code" => facility_properties[f.code], "codingScheme" => f.metadata_value_for("codingScheme")) do
        xml.text!(f.human_value_by_option_code(facility_properties[f.code]))
      end
    end
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
    xml.tag!("record",
      "created" => facility["_source"]["created_at"].to_datetime.iso8601,
      "updated" => facility["_source"]["updated_at"].to_datetime.iso8601,
      "status" => "Active",
      "sourceDirectory" => "http://#{Settings.host}")

    xml
  end

  def generate_languages(xml, facility_properties)
    @language_fields.each do |language_field|
      value = facility_properties[language_field.code] || ""
      schema = language_field.metadata_value_for("codingScheme") || ""
      xml.tag!("language", "code" => value, "codingScheme" => schema) do
        xml.text!(language_field.human_value_by_option_code(value))
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
            xml.tag!("codingScheme", schema)
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
        xml.tag!("codingScheme", schema)
      end
    end
    xml
  end

  def generate_entity_id(facility, facility_properties)
    #If there's an explicitly set up EntityID, use its value as is, otherwise we use the UUID.
    if @entity_id_field
      facility_properties[@entity_id_field.code] || ""
    else
      facility["_source"]["uuid"]
    end
  end

  def generate_other_ids(xml, facility_properties)
    @identifier_fields.each do |identifier_field|
      value = facility_properties[identifier_field.code] || ""
      xml.tag!("otherID", "code" => value, "assigningAuthorityName" => identifier_field.agency)
    end

    xml
  end
end
