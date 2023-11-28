# encoding: UTF-8
require 'spec_helper'

describe CsdApiController, :type => :controller do
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

    it 'should return forbidden in get_directory_modifications if user tries to access a collection of which he is not member'  do
      not_member = User.make
      sign_in not_member
      request_id = "urn:uuid:4924fff9-e0f4-48c8-a403-955760fcc667"
      request.env["RAW_POST_DATA"] = generate_request(request_id)
      post :get_directory_modifications, params: { collection_id: collection.id }
      expect(response.status).to eq(403)
    end

    it "should accept SOAP request and respond with a valid envelope" do
      request_id = "urn:uuid:4924fff9-e0f4-48c8-a403-955760fcc667"
      request.env["RAW_POST_DATA"] = generate_request(request_id)

      post :get_directory_modifications, params: { collection_id: collection.id }
      expect(response.status).to eq(200)

      response_hash = Hash.from_xml(response.body)


      # Valid Envelope attributes
      assert expect(response_hash["Envelope"]).to include( {"xmlns:soap"=>"http://www.w3.org/2003/05/soap-envelope", "xmlns:wsa"=>"http://www.w3.org/2005/08/addressing", "xmlns:csd"=>"urn:ihe:iti:csd:2013"} )

      # Valid 'Action' in Header
      expect(response_hash["Envelope"]["Header"]["Action"]).to eq("urn:ihe:iti:csd:2013:GetDirectoryModificationsResponse")

      # Valid 'MessageId' in Header
      message_id = response_hash["Envelope"]["Header"]["MessageID"]
      assert expect(message_id).to be
      assert expect(message_id).to start_with "urn:uuid:"
      uuid = message_id.split(':').last
      expect(UUIDTools::UUID.parse uuid).to be_valid

      # Valid anonymous 'To' in Header
      assert expect(response_hash["Envelope"]["Header"]["To"]).to eq("http://www.w3.org/2005/08/addressing/anonymous")

      # Valid 'RelatesTo' in Header
      assert expect(response_hash["Envelope"]["Header"]["RelatesTo"]).to eq(request_id)

      # Valid Body attibutes
      body = response_hash["Envelope"]["Body"]["getModificationsResponse"]["CSD"]
      expect(body).to include({"xmlns"=>"urn:ihe:iti:csd:2013", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation"=>"urn:ihe:iti:csd:2013 CSD.xsd"})

      expect(body.has_key?("organizationDirectory")).to be_truthy
      expect(body.has_key?("serviceDirectory")).to be_truthy
      expect(body.has_key?("facilityDirectory")).to be_truthy
      expect(body.has_key?("providerDirectory")).to be_truthy

    end

    # Request Validation is currenty commented in the code because it takes too long
    skip "should respond whit an error on invalid datetime element" do
      request.env["RAW_POST_DATA"] =  generate_request("hello", "hello")

      post :get_directory_modifications, params: { collection_id: collection.id }

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

      expect(Hash.from_xml(response.body)).to eq(Hash.from_xml(expected_xml))
      expect(@response.status).to eq(500)
    end

    # Request Validation is currenty commented in the code because it takes too long
    skip "should respond whit an error on invalid soap message" do
      request.env["RAW_POST_DATA"] =  %Q{"hello"}

      post :get_directory_modifications, params: { collection_id: collection.id }

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

      expect(Hash.from_xml(response.body)).to eq(Hash.from_xml(expected_xml))
      expect(@response.status).to eq(500)
    end

    it "should return facilities modified after a particular date" do
      stub_time Time.iso8601("2012-11-18T15:40:28-03:00").to_s

      site_a = collection.sites.make name: 'Site A'
      site_b = collection.sites.make name: 'Site B', uuid: "f81d4fae-7dec-11d0-a765-00a0c91e6bf6"

      stub_time Time.iso8601("2013-11-18T15:40:28-03:00").to_s
      site_a.name = 'Site A changed'
      site_a.save!

      stub_time Time.iso8601("2013-11-19T15:40:28-03:00").to_s
      site_b.name = 'Site B changed'
      site_b.save!

      request.env["RAW_POST_DATA"] = generate_request("urn:uuid:47b8c0c2-1eb1-4b4b-9605-19f091b64fb1", "2013-11-18T20:40:28-03:00")
      post :get_directory_modifications, params: { collection_id: collection.id }
      response_hash = Hash.from_xml(response.body)

      body = response_hash["Envelope"]["Body"]["getModificationsResponse"]["CSD"]

      expect(body["facilityDirectory"].length).to eq(1)
      facility = body["facilityDirectory"]["facility"]
      expect(facility["primaryName"]).to eq('Site B changed')
    end

    #TODO: simplify test by using new utility methods
    it "should return CSD facility attributes for each CSD-field in the collection" do
      layer = collection.layers.make

      # Identifiers fields for otherId
      identifier_field = layer.identifier_fields.make code: 'moh-id', :config => {"context" => "MOH", "agency" => "DHIS", "format" => "Normal"}
      identifier_field_2 = layer.identifier_fields.make code: 'rw-id', :config => {"context" => "RW facility list", "agency" => "RW", "format" => "Normal"}

      # Select One fields with metadata for codedType
      select_one_field = layer.select_one_fields.make code: 'moh-schema-option', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"codedType"}, "1"=>{"key"=>"codingSchema", "value"=>"moh.gov.rw"}}, :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]}

      # Text fields with metadata for otherName
      french_name_field = layer.text_fields.make code: 'French Name', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"otherName"}, "1"=>{"key"=>"CSDLanguage", "value"=>"french"}}
      spanish_name_field = layer.text_fields.make code: 'Spanish Name', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"otherName"}, "1"=>{"key"=>"CSDLanguage", "value"=>"spanish"}}

      # Text fields with metadata for address
      city_fiscal_address_field = layer.text_fields.make code: 'fiscal city', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"address"}, "1"=>{"key"=>"CSDComponent", "value"=>"City"}, "2"=>{"key"=>"CSDCode", "value"=>"FiscalAddress"}}
      street_fiscal_address_field = layer.text_fields.make code: 'fiscal street', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"address"}, "1"=>{"key"=>"CSDComponent", "value"=>"StreetAddress"}, "2"=>{"key"=>"CSDCode", "value"=>"FiscalAddress"}}

      city_real_address_field = layer.text_fields.make code: 'real city', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"address"}, "1"=>{"key"=>"CSDComponent", "value"=>"City"}, "2"=>{"key"=>"CSDCode", "value"=>"RealAddress"}}
      street_real_address_field = layer.text_fields.make code: 'real street', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"address"}, "1"=>{"key"=>"CSDComponent", "value"=>"StreetAddress"}, "2"=>{"key"=>"CSDCode", "value"=>"RealAddress"}}

      # Text fields with metadata for contactPoint
      contact1_equipment_field = layer.text_fields.make code: 'Contact Equipment', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"contactPoint"}, "1"=>{"key"=>"CSDContactData", "value"=>"Equipment"}, "2"=>{"key"=>"CSDCode", "value"=>"ContactOne"}}

      contact1_purpose_field = layer.text_fields.make code: 'Contact Purpose', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"contactPoint"}, "1"=>{"key"=>"CSDContactData", "value"=>"Purpose"}, "2"=>{"key"=>"CSDCode", "value"=>"ContactOne"}}

      contact1_certificate_field = layer.text_fields.make code: 'Contact Certificate', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"contactPoint"}, "1"=>{"key"=>"CSDContactData", "value"=>"Certificate"}, "2"=>{"key"=>"CSDCode", "value"=>"ContactOne"}}

      contact1_coded_type_field = layer.select_one_fields.make code: 'Contact Coded Type', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"contactPoint"}, "1"=>{"key"=>"OptionList", "value"=>"moh.gov.rw"}, "2"=>{"key"=>"CSDCode", "value"=>"ContactOne"}}, :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]}

      contact2_equipment_field = layer.text_fields.make code: 'Contact 2 Equipment', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"contactPoint"}, "1"=>{"key"=>"CSDContactData", "value"=>"Equipment"}, "2"=>{"key"=>"CSDCode", "value"=>"ContactTwo"}}

      # Select One fields with metadata for languages
      language_field = layer.select_one_fields.make code: 'language', "metadata"=>{"0"=>{"key"=>"CSDType", "value"=>"language"}, "1"=>{"key"=>"OptionList", "value"=>"BCP 47"}}, :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'spanish', 'label' => 'Spanish'}, {'id' => 2, 'code' => 'french', 'label' => 'French'}]}

      # Yes-No field for active
      status_field = layer.yes_no_fields.make code: 'active', "metadata" => {"0" => {"key" => "CSDType", "value"=> "status"}}

      stub_time Time.iso8601("2013-12-18T15:40:28-03:00").to_s
      site_a = collection.sites.make(name: 'Site A', lat: 10, lng: 20, properties: {
          identifier_field.es_code => "12345",
          select_one_field.es_code => 1,
          french_name_field.es_code => "Terrain A",
          spanish_name_field.es_code => "Sitio A",
          city_fiscal_address_field.es_code => "Buenos Aires",
          street_fiscal_address_field.es_code => "Balcarce 50",
          city_real_address_field.es_code => "Vicente Lopez",
          street_real_address_field.es_code => "Bartolome Cruz 1818",
          contact1_equipment_field.es_code => "Equipment for contact 1",
          contact1_purpose_field.es_code => "Main contact",
          contact1_certificate_field.es_code => "1234",
          contact1_coded_type_field.es_code => 2,
          contact2_equipment_field.es_code => "Contact 2",
          language_field.es_code => 2,
          status_field.es_code => false})

      request.env["RAW_POST_DATA"] = generate_request("urn:uuid:47b8c0c2-1eb1-4b4b-9605-19f091b64fb1", "2013-11-18T20:40:28-03:00")
      post :get_directory_modifications, params: { collection_id: collection.id }

      # Hash.from_xml doesn't take into account attributes.
      # Have to change this to use Nokogiri.
      # Not a big deal if have strong unit tests.
      response_hash = Hash.from_xml(response.body)

      body = response_hash["Envelope"]["Body"]["getModificationsResponse"]["CSD"]

      expect(body["facilityDirectory"].length).to eq(1)

      facility = body["facilityDirectory"]["facility"]

      # Should include 'name'
      name = facility["primaryName"]
      expect(name).to eq 'Site A'

      # Should include 'otherName's
      other_names = facility["otherName"]
      expect(other_names.length).to eq(2)

      expect(other_names.first["language"]).to eq "french"
      expect(other_names.first["commonName"]).to eq "Terrain A"

      expect(other_names.last["language"]).to eq "spanish"
      expect(other_names.last["commonName"]).to eq "Sitio A"

      # Should include 'geocode'
      expect(facility["geocode"]["latitude"]).to eq("10.0")
      expect(facility["geocode"]["longitude"]).to eq("20.0")

      # Should include 'contactPoint'
      expect(facility["contactPoint"].length).to eq(2)
      contact1 = facility["contactPoint"][0]
      expect(contact1["equipment"]).to eq("Equipment for contact 1")
      expect(contact1["purpose"]).to eq("Main contact")
      expect(contact1["certificate"]).to eq("1234")
      expect(contact1["codedType"]["code"]).to eq "two"
      expect(contact1["codedType"]["codingScheme"]).to eq "moh.gov.rw"

      contact2 = facility["contactPoint"][1]
      expect(contact2["equipment"]).to eq("Contact 2")

      # Should include 'record'
      expect(facility["record"]["created"]).to eq("2013-12-18T18:40:28+00:00")
      expect(facility["record"]["updated"]).to eq("2013-12-18T18:40:28+00:00")
      expect(facility["record"]["sourceDirectory"]).to eq("http://#{Settings.host}")
      expect(facility["record"]["status"]).to eq("Active")
    end
  end

  describe "SOAP Service API Version 1.1" do
    it "should return CSD facility attributes for each CSD-field in the collection" do

      collection_2 = Collection.create! name: "CSD #{Time.now}", icon: "default"
      user.create_collection collection_2
      SampleCollectionGenerator.fill collection_2

      request.env["RAW_POST_DATA"] = generate_request("urn:uuid:47b8c0c2-1eb1-4b4b-9605-19f091b64fb1", "2013-11-18T20:40:28-03:00")
      post :get_directory_modifications, params: { collection_id: collection_2.id }

      response_xml = Nokogiri::XML(response.body) do |config|
        config.strict.noblanks
      end.xpath('//soap:Body')

      result_xml = Nokogiri::XML(File.open("#{Rails.root}/plugins/csd_api/spec/controllers/csd-facilities-connectathon-result.xml.erb")) do |config|
        config.strict.noblanks
      end.xpath('//soap:Body')

      expect(response_xml.to_s).to eq(result_xml.to_s)
    end
  end

end
