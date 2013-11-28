module CsdApiHelper

  def facilities_directory_xml_for_get_modifications(xml, facilities, request_id, collection)
    # Used to generate 'otherId's
    identifier_fields = collection.identifier_fields

    #Used to generate 'facilityTypes's
    facility_type_fields = collection.facility_type_fields


    xml.soap(:Envelope, xs_header_specification) do
      xml.soap :Header do
        xml.tag!("wsa:Action", { "soap:mustUnderstand" => "1"}) do
          xml.text!("urn:ihe:iti:csd:2013:GetDirectoryModificationsResponse")
        end

        xml.tag!("wsa:MessageID") do
          xml.text!("urn:uuid:#{UUIDTools::UUID.random_create.to_s}")
        end

        xml.tag!("wsa:To", { "soap:mustUnderstand" => "1"}) do
          xml.text!("http://www.w3.org/2005/08/addressing/anonymous")
        end

        xml.tag!("wsa:RelatesTo") do
          xml.text!(request_id)
        end
      end

       xml.soap :Body do
        xml.tag!("csd:getModificationsResponse") do
          xml.tag!("CSD", { "xmlns" => "urn:ihe:iti:csd:2013",  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",  "xsi:schemaLocation"=>"urn:ihe:iti:csd:2013 CSD.xsd"}) do

            xml.tag!("organizationDirectory")

            xml.tag!("serviceDirectory")

            xml.tag!("facilityDirectory") do
              facilities.each do |facility|
                facility_xml xml, facility, identifier_fields, facility_type_fields
              end
            end

            xml.tag!("providerDirectory")

          end
        end
      end

    end
  end

  private

  def facility_xml(xml, facility, identifier_fields, facility_type_fields)

    facility_properties = facility["_source"]["properties"]

    xml.tag!("facility") do
      xml.tag!("oid", generate_oid(facility))
      identifier_fields.each do |identifier_field|
        xml.tag!("otherID") do
          value = facility_properties[identifier_field.code] || ""
          xml.tag!("code", value)
          agency = identifier_field.agency
          xml.tag!("assigningAuthorityName", agency)
        end
      end

      facility_type_fields.each do |facility_type_field|
        xml.tag!("codedType") do
          value = facility_properties[facility_type_field.code] || ""
          xml.tag!("code", value)
          # TODO: move this to a method
          schema = facility_type_field.metadata["OptionList"] || ""
          xml.tag!("codingSchema", schema)
        end
        xml.tag!("primaryName", facility["_source"]["name"])
      end
    end

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

  def xs_header_specification
    {
      'xmlns:soap' => "http://www.w3.org/2003/05/soap-envelope",
      'xmlns:wsa'  => "http://www.w3.org/2005/08/addressing",
      'xmlns:csd'  => "urn:ihe:iti:csd:2013",
    }
  end

end

module SoapFault
  class ClientError < StandardError
    def fault_code
      "Client"
    end
  end

  class MustUnderstandError < StandardError
    def fault_code
      "MustUnderstand"
    end
  end
end
