require 'spec_helper'

describe CsdApiController do
  include Devise::TestHelpers
  render_views

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make) }

  before(:each) { sign_in user }

  def generate_request(timestamp = "2013-10-01T00:00:00+00:00")
    %Q{
    <soap:Envelope xmlns:csd="urn:ihe:iti:csd:2013" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
      <soap:Header>
        <wsa:Action soap:mustUnderstand="1">
          urn:ihe:iti:csd:2013:GetDirectoryModificationsRequest
        </wsa:Action>
        <wsa:MessageID>urn:uuid:26c27ce7-4470-4f59-bc22-3ede0bd084a0</wsa:MessageID>
        <wsa:ReplyTo soap:mustUnderstand="1">
          <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>
        </wsa:ReplyTo>
        <wsa:To soap:mustUnderstand="1">
          http://rhea-pr.ihris.org/providerregistry/getUpdatedServices
        </wsa:To>
      </soap:Header>
      <soap:Body>
        <csd:getModificationsRequest>
          <csd:lastModified>#{timestamp}</csd:lastModified>
        </csd:getModificationsRequest>
      </soap:Body>
    </soap:Envelope>
    }
  end

  def generate_response(facilities_xml = nil)
    %Q{
      <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:csd="urn:ihe:iti:csd:2013">
        <soap:Header>
          <wsa:Action soap:mustUnderstand="1">urn:ihe:iti:csd:2013:GetDirectoryModificationsResponse</wsa:Action>
          <wsa:MessageID>urn:uuid:40973a4f-1e5c-4b69-8db1-601eb64a0f25</wsa:MessageID>
          <wsa:To soap:mustUnderstand="1">http://www.w3.org/2005/08/addressing/anonymous</wsa:To>
          <wsa:RelatesTo>urn:uuid:b75f1d11-ee35-488a-9f6e-16db3713906c</wsa:RelatesTo>
        </soap:Header>
        <soap:Body>
          <csd:getModificationsResponse>
            <CSD xmlns="urn:ihe:iti:csd:2013" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ihe:iti:csd:2013 CSD.xsd">
              <organizationDirectory/>
              <serviceDirectory/>
              <facilityDirectory/>
              <providerDirectory/>
            </CSD>
          </csd:getModificationsResponse>
        </soap:Body>
      </soap:Envelope>
    }
  end

  describe "SOAP Service" do

    it "should accept SOAP request" do
      request.env["RAW_POST_DATA"] = generate_request()

      post :directories, collection_id: collection.id

      expected = Hash.from_xml(generate_response())
      response_hash = Hash.from_xml(response.body)

      assert_equal expected, response_hash
      assert_equal 200, response.status
    end

    it  "should respond whit an error on invalid datetime element" do
      request.env["RAW_POST_DATA"] =  generate_request("hello")

      post :directories, collection_id: collection.id

      expected_xml = %Q{
        <SOAP:Envelope xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/">
          <SOAP:Body>
            <SOAP:Fault>
              <faultcode>SOAP:Client</faultcode>
              <faultstring>Element '{urn:ihe:iti:csd:2013}lastModified': 'hello' is not a valid value of the atomic type 'xs:dateTime'.</faultstring>
            </SOAP:Fault>
          </SOAP:Body>
        </SOAP:Envelope>
      }

      expected = Hash.from_xml(expected_xml)
      response_hash = Hash.from_xml(response.body)

      assert_equal expected, response_hash
      assert_equal 500, @response.status
    end
  end

end
