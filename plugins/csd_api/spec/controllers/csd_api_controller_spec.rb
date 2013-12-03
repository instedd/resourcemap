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

      post :get_directory_modifications, collection_id: collection.id
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

      post :get_directory_modifications, collection_id: collection.id

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

      post :get_directory_modifications, collection_id: collection.id

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
      post :get_directory_modifications, collection_id: collection.id
      response_hash = Hash.from_xml(response.body)

      body = response_hash["Envelope"]["Body"]["getModificationsResponse"]["CSD"]

      body["facilityDirectory"].length.should eq(1)
      facility = body["facilityDirectory"]["facility"]
      facility["oid"].should eq("2.25.309768652999692686176651983274504471835.646.5.329800735698586629295641978511506172918")

    end

    it "should return CSD facility attributes for each CSD-field in the collection" do
      layer = collection.layers.make

      # Identifiers fields for otherId
      identifier_field = layer.identifier_fields.make code: 'moh-id', :config => {"context" => "MOH", "agency" => "DHIS", "format" => "Normal"}
      identifier_field_2 = layer.identifier_fields.make code: 'rw-id', :config => {"context" => "RW facility list", "agency" => "RW", "format" => "Normal"}

      # Select One fields with metadata for codedType
      select_one_field = layer.select_one_fields.make code: 'moh-schema-option', metadata: {"CSDType" => "facilityType", "OptionList" => "moh.gov.rw"}, :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]}
      stub_time Time.iso8601("2013-12-18T15:40:28-03:00").to_s

      # Text fields with metadata for otherName
      french_name_field = layer.text_fields.make code: 'French Name', metadata: {"CSDType" => "otherName", "CSDLanguage" => "french"}
      spanish_name_field = layer.text_fields.make code: 'Spanish Name', metadata: {"CSDType" => "otherName", "CSDLanguage" => "spanish"}

      # Text fields with metadata for address
      city_fiscal_address_field = layer.text_fields.make code: 'fiscal city', metadata: {"CSDType" => "address", "CSDComponent" => "City", "CSDCode" => "FiscalAddress"}
      street_fiscal_address_field = layer.text_fields.make code: 'fiscal street', metadata: {"CSDType" => "address", "CSDComponent" => "StreetAddress", "CSDCode" => "FiscalAddress"}

      city_real_address_field = layer.text_fields.make code: 'real city', metadata: {"CSDType" => "address", "CSDComponent" => "City", "CSDCode" => "RealAddress"}
      street_real_address_field = layer.text_fields.make code: 'real street', metadata: {"CSDType" => "address", "CSDComponent" => "StreetAddress", "CSDCode" => "RealAddress"}

      # Text fields with metadata for contactPoint
      contact1_equipment_field = layer.text_fields.make code: 'Contact Equipment', metadata: {"CSDType" => "contactPoint", "CSDContactData" => "Equipment", "CSDCode" => "ContactOne"}
      contact1_purpose_field = layer.text_fields.make code: 'Contact Purpose', metadata: {"CSDType" => "contactPoint", "CSDContactData" => "Purpose", "CSDCode" => "ContactOne"}
      contact1_certificate_field = layer.text_fields.make code: 'Contact Certificate', metadata: {"CSDType" => "contactPoint", "CSDContactData" => "Certificate", "CSDCode" => "ContactOne"}
      contact1_coded_type_field = layer.select_one_fields.make code: 'Contact Coded Type', metadata: {"CSDType" => "contactPoint", "OptionList" => "moh.gov.rw", "CSDCode" => "ContactOne"}, :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]}

      contact2_equipment_field = layer.text_fields.make code: 'Contact 2 Equipment', metadata: {"CSDType" => "contactPoint", "CSDContactData" => "Equipment", "CSDCode" => "ContactTwo"}

      # Select One fields with metadata for languages
      language_field = layer.select_one_fields.make code: 'language', metadata: {"CSDType" => "language", "OptionList" => "BCP 47"}, :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'spanish', 'label' => 'Spanish'}, {'id' => 2, 'code' => 'french', 'label' => 'French'}]}


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
          language_field.es_code => 2})

      request.env["RAW_POST_DATA"] = generate_request("urn:uuid:47b8c0c2-1eb1-4b4b-9605-19f091b64fb1", "2013-11-18T20:40:28-03:00")
      post :get_directory_modifications, collection_id: collection.id
      response_hash = Hash.from_xml(response.body)

      body = response_hash["Envelope"]["Body"]["getModificationsResponse"]["CSD"]

      body["facilityDirectory"].length.should eq(1)

      facility = body["facilityDirectory"]["facility"]

      # Should include 'otherId'
      other_ids = facility["otherID"]
      other_ids.length.should eq(2)

      other_id_1 = other_ids.first
      other_id_1["code"].should eq("12345")
      other_id_1["assigningAuthorityName"].should eq("DHIS")

      other_id_2 = other_ids.last
      other_id_2["code"].should eq(nil)
      other_id_2["assigningAuthorityName"].should eq("RW")

      # Should include 'codedType'
      coded_type = facility["codedType"]
      coded_type["code"].should eq("one")
      coded_type["codingSchema"].should eq("moh.gov.rw")

      # Should include 'name'
      name = facility["primaryName"]
      name.should eq 'Site A'

      # Should include 'otherName's
      other_names = facility["otherName"]
      other_names.length.should eq(2)

      other_names.first["language"].should eq "french"
      other_names.first["commonName"].should eq "Terrain A"

      other_names.last["language"].should eq "spanish"
      other_names.last["commonName"].should eq "Sitio A"

      # Should include 'address', one for each type
      addresses = facility["address"]
      addresses.length.should eq(2)

      fiscal_address = addresses.first
      fiscal_address["type"].should eq("FiscalAddress")
      fiscal_address["addressLine"].length.should eq(2)
      fiscal_address["addressLine"][0].should eq("Buenos Aires")
      fiscal_address["addressLine"][1].should eq("Balcarce 50")

      real_address = addresses.last
      real_address["type"].should eq("RealAddress")
      real_address["addressLine"].length.should eq(2)
      real_address["addressLine"][0].should eq("Vicente Lopez")
      real_address["addressLine"][1].should eq("Bartolome Cruz 1818")

      # Should include 'geocode'
      facility["geocode"]["latitude"].should eq("10.0")
      facility["geocode"]["longitude"].should eq("20.0")
      facility["geocode"]["coordinateSystem"].should eq("WGS-84")

      # Should include 'contactPoint'
      facility["contactPoint"].length.should eq(2)
      contact1 = facility["contactPoint"][0]
      contact1["equipment"].should eq("Equipment for contact 1")
      contact1["purpose"].should eq("Main contact")
      contact1["certificate"].should eq("1234")
      contact1["codedType"]["code"].should eq "two"
      contact1["codedType"]["codingSchema"].should eq "moh.gov.rw"

      contact2 = facility["contactPoint"][1]
      contact2["equipment"].should eq("Contact 2")

      # Should include 'language'
      facility["language"]["code"].should eq("french")
      facility["language"]["codingSchema"].should eq("BCP 47")

    end

  end

end
