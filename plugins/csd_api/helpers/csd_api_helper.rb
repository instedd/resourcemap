module CsdApiHelper

  # TODO: is RealtesTo attribute a variable??
  def facilities_directory_xml(xml, facilities, action="GetDirectoryModificationsResponse", message_id="urn:uuid:40973a4f-1e5c-4b69-8db1-601eb64a0f25")
    xml.soap(:Envelope, xs_header_specification) do
      xml.soap :Header do
        xml.tag!("wsa:Action", { "soap:mustUnderstand" => "1"}) do
          xml.text!("urn:ihe:iti:csd:2013:#{action}")
        end

        xml.tag!("wsa:MessageID") do
          #TODO generate a new UUID
          xml.text!("#{message_id}")
        end

        xml.tag!("wsa:To", { "soap:mustUnderstand" => "1"}) do
          xml.text!("http://www.w3.org/2005/08/addressing/anonymous")
        end

        # TODO: Use the UUID in the request
        xml.tag!("wsa:RelatesTo") do
          xml.text!("urn:uuid:b75f1d11-ee35-488a-9f6e-16db3713906c")
        end
      end

       xml.soap :Body do
        xml.tag!("csd:getModificationsResponse") do
          xml.tag!("CSD", { "xmlns" => "urn:ihe:iti:csd:2013",  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",  "xsi:schemaLocation"=>"urn:ihe:iti:csd:2013 CSD.xsd"}) do

            xml.tag!("organizationDirectory")

            xml.tag!("serviceDirectory")

            xml.tag!("facilityDirectory")

            xml.tag!("providerDirectory")

          end
        end
      end

    end
  end

  private

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
