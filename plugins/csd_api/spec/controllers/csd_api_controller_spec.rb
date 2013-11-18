require 'spec_helper'

describe CsdApiController do
  include Devise::TestHelpers
  render_views

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make) }

  before(:each) { sign_in user }

  def generate_request(message_id = "urn:uuid:26c27ce7-4470-4f59-bc22-3ede0bd084a0", timestamp = "2013-10-01T00:00:00+00:00")
    %Q{
    <soap:Envelope xmlns:csd="urn:ihe:iti:csd:2013" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
      <soap:Header>
        <wsa:Action soap:mustUnderstand="1">
          urn:ihe:iti:csd:2013:GetDirectoryModificationsRequest
        </wsa:Action>
        <wsa:MessageID>#{message_id}</wsa:MessageID>
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

  describe "SOAP Service" do

    it "should accept SOAP request and respond with a valid envelope" do
      request_id = "urn:uuid:4924fff9-e0f4-48c8-a403-955760fcc667"
      request.env["RAW_POST_DATA"] = generate_request(request_id)

      post :directories, collection_id: collection.id
      assert_equal 200, response.status

      response_hash = Hash.from_xml(response.body)


      # Valid Envelope attributes
      assert response_hash["Envelope"].should include( {"xmlns:soap"=>"http://www.w3.org/2003/05/soap-envelope", "xmlns:wsa"=>"http://www.w3.org/2005/08/addressing", "xmlns:csd"=>"urn:ihe:iti:csd:2013"} )

      # Valid 'Action' in Header
      response_hash["Envelope"]["Header"]["Action"].should eq("urn:ihe:iti:csd:2013:GetDirectoryModificationsResponse")

      # Valid 'MessageId' in Header
      message_id = response_hash["Envelope"]["Header"]["MessageID"]
      assert message_id.should be
      assert message_id.should start_with "urn:uuid:"
      uuid = message_id.split(':').last
      (UUIDTools::UUID.parse uuid).should be_valid

      # Valid anonymous 'To' in Header
      assert response_hash["Envelope"]["Header"]["To"].should eq("http://www.w3.org/2005/08/addressing/anonymous")

      # Valid 'RelatesTo' in Header
      assert response_hash["Envelope"]["Header"]["RelatesTo"].should eq(request_id)

      # Valid Body attibutes
      body = response_hash["Envelope"]["Body"]["getModificationsResponse"]["CSD"]
      body.should include({"xmlns"=>"urn:ihe:iti:csd:2013", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation"=>"urn:ihe:iti:csd:2013 CSD.xsd"})

      body.has_key?("organizationDirectory").should be_true
      body.has_key?("serviceDirectory").should be_true
      body.has_key?("facilityDirectory").should be_true
      body.has_key?("providerDirectory").should be_true

    end

    it  "should respond whit an error on invalid datetime element" do
      request.env["RAW_POST_DATA"] =  generate_request("hello", "hello")

      post :directories, collection_id: collection.id

      expected_xml = %Q{
        <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
          <soap:Body>
            <soap:Fault>
              <faultcode>soap:Client</faultcode>
              <faultstring>Element '{urn:ihe:iti:csd:2013}lastModified': 'hello' is not a valid value of the atomic type 'xs:dateTime'.</faultstring>
            </soap:Fault>
          </soap:Body>
        </soap:Envelope>
      }

      expected = Hash.from_xml(expected_xml)
      response_hash = Hash.from_xml(response.body)

      assert_equal expected, response_hash
      assert_equal 500, @response.status
    end

    it  "should respond whit an error on invalid soap message" do
      request.env["RAW_POST_DATA"] =  %Q{"hello"}

      post :directories, collection_id: collection.id

      expected_xml = %Q{
        <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
          <soap:Body>
            <soap:Fault>
              <faultcode>soap:Client</faultcode>
              <faultstring>The document has no document element.</faultstring>
            </soap:Fault>
          </soap:Body>
        </soap:Envelope>
      }

      expected = Hash.from_xml(expected_xml)
      response_hash = Hash.from_xml(response.body)

      assert_equal expected, response_hash
      assert_equal 500, @response.status
    end

  end

end
