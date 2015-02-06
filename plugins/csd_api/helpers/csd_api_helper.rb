require "facility_xml_generator"

module CsdApiHelper

  def facilities_directory_xml_for_get_modifications(xml, facilities, request_id, collection)
    xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
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

            facility_xml_generator = FacilityXmlGenerator.new(collection)

            xml.tag!("facilityDirectory") do
              facilities.each do |facility|
                if is_csd_complete(facility)
                  facility_xml_generator.generate_facility_xml xml, facility
                end
              end
            end

            xml.tag!("providerDirectory")

          end
        end
      end
    end
  end

  def services_directory_xml_for_get_modifications(xml, services, request_id, collection)
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

            service_xml_generator = ServiceXmlGenerator.new(collection)

            xml.tag!("serviceDirectory") do
              services.each do |service|
                service_xml_generator.generate_service_xml xml, service
              end
            end

            xml.tag!("facilityDirectory")

            xml.tag!("providerDirectory")
          end
        end
      end
    end
  end

  def organizations_directory_xml_for_get_modifications(xml, organizations, request_id, collection)
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
            organization_xml_generator = OrganizationXmlGenerator.new(collection)

            xml.tag!("organizationDirectory") do
              organizations.each do |organization|
                organization_xml_generator.generate_organization_xml xml, organization
              end
            end

            xml.tag!("serviceDirectory")

            xml.tag!("facilityDirectory")

            xml.tag!("providerDirectory")
          end
        end
      end
    end
  end

  private

  def is_csd_complete(facility)
    begin
      facility["_source"]["location"]["lon"]
      facility["_source"]["location"]["lat"]
    rescue
      false
    end
  end

  def xs_header_specification
    {
      'xmlns:soap' => "http://www.w3.org/2003/05/soap-envelope",
      'xmlns:wsa'  => "http://www.w3.org/2005/08/addressing",
      'xmlns:csd'  => "urn:ihe:iti:csd:2013",
    }
  end
end


