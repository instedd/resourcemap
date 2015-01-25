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
      post :get_directory_modifications, collection_id: collection.id
      expect(response.status).to eq(403)
    end

    it "should accept SOAP request and respond with a valid envelope" do
      request_id = "urn:uuid:4924fff9-e0f4-48c8-a403-955760fcc667"
      request.env["RAW_POST_DATA"] = generate_request(request_id)

      post :get_directory_modifications, collection_id: collection.id
      assert_equal 200, response.status

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

    # Request Validation is currenty commented in the code because it takes too long
    skip "should respond whit an error on invalid soap message" do
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
      post :get_directory_modifications, collection_id: collection.id

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
      user = collection.get_user_owner

      layer = collection.layers.make name: 'Connectathon Fields'
      coded_type_medical_specialty = layer.select_one_fields.create!(ord: 1, name: 'Medical Specialty', code: 'medical_specialty',
        config: {'options' =>[
          {'id' => 1, 'code' => '103-110', 'label' => 'Radiology - Imaging Services'},
          {'id' => 2, 'code' => '103-003', 'label' => 'Dialysis'}]})
        .csd_coded_type! "1.3.6.1.4.1.21367.100.1"

      entity_id_field = layer.identifier_fields.create!(ord: 2, name: "Entity ID", code: "entity_id").csd_facility_entity_id!

      contact_1_common_name_field = layer.text_fields.create!(ord: 3, name: "Common Name Contact 1", code: 'common_name_contact_1')
        .csd_contact("Contact 1").csd_name("Name 1", Field::CSDApiConcern::csd_contact_tag).csd_common_name!("en")
      contact_1_forename_field = layer.text_fields.create!(ord: 4, name: "Forename Contact 1", code: 'forename_contact_1')
        .csd_contact("Contact 1").csd_name("Name 1", Field::CSDApiConcern::csd_contact_tag).csd_forename!
      contact_1_surname_field = layer.text_fields.create!(ord: 5, name: "Surname Contact 1", code: 'surname_contact_1')
        .csd_contact("Contact 1").csd_name("Name 1", Field::CSDApiConcern::csd_contact_tag).csd_surname!
      contact_1_street_address_field = layer.text_fields.create!(ord: 6, name: "StreetAddress Contact 1", code: "street_address_contact_1")
        .csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("streetAddress")
      contact_1_city_field =  layer.text_fields.create!(ord: 7, name: "City Contact 1", code: 'city_contact_1')
        .csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("city")
      contact_1_state_province_field = layer.text_fields.create!(ord: 8, name: "StateProvince Contact 1", code: 'state_province_contact_1')
        .csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("stateProvince")
      contact_1_country_field = layer.text_fields.create!(ord: 9, name: "Country Contact 1", code: 'country_contact_1')
        .csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("country")
      contact_1_postal_code_field = layer.text_fields.create!(ord: 10, name: "PostalCode Contact 1", code: 'postal_code_contact_1')
        .csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("postalCode")


      contact_2_common_name_field = layer.text_fields.create!(ord: 11, name: "Common Name Contact 2", code: 'common_name_contact_2')
        .csd_contact("Contact 2").csd_name("Name 2", Field::CSDApiConcern::csd_contact_tag).csd_common_name!("en")
      contact_2_forename_field = layer.text_fields.create!(ord: 12, name: "Forename Contact 2", code: 'forename_contact_2')
        .csd_contact("Contact 2").csd_name("Name 2", Field::CSDApiConcern::csd_contact_tag).csd_forename!
      contact_2_surname_field = layer.text_fields.create!(ord: 13, name: "Surname Contact 2", code: 'surname_contact_2')
        .csd_contact("Contact 2").csd_name("Name 2", Field::CSDApiConcern::csd_contact_tag).csd_surname!
      contact_2_street_address_field = layer.text_fields.create!(ord: 6, name: "StreetAddress Contact 2", code: "street_address_contact_2")
        .csd_contact("Contact 2").csd_address("Address 2", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("streetAddress")
      contact_2_city_field =  layer.text_fields.create!(ord: 7, name: "City Contact 2", code: 'city_contact_2')
        .csd_contact("Contact 2").csd_address("Address 2", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("city")
      contact_2_state_province_field = layer.text_fields.create!(ord: 8, name: "StateProvince Contact 2", code: 'state_province_contact_2')
        .csd_contact("Contact 2").csd_address("Address 2", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("stateProvince")
      contact_2_country_field = layer.text_fields.create!(ord: 9, name: "Country Contact 2", code: 'country_contact_2')
        .csd_contact("Contact 2").csd_address("Address 2", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("country")
      contact_2_postal_code_field = layer.text_fields.create!(ord: 10, name: "PostalCode Contact 2", code: 'postal_code_contact_2')
        .csd_contact("Contact 2").csd_address("Address 2", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("postalCode")

      language_config = {
        options: [
          {id: 1, code: "en", label: "English"},
          {id: 2, code: "es", label: "Spanish"},
          {id: 3, code: "fr", label: "French"}
        ]
      }.with_indifferent_access

      language_1_field = layer.select_one_fields.create!(ord: 11, name: "Language 1", code: 'language_1', config: language_config)
        .csd_language!("BCP 47", Field::CSDApiConcern::csd_facility_tag)
      language_2_field = layer.select_one_fields.create!(ord: 12, name: "Language 2", code: 'language_2', config: language_config)
        .csd_language!("BCP 47", Field::CSDApiConcern::csd_facility_tag)

      oh_1_open_flag_field = layer.yes_no_fields.create!(ord: 13, name: "Open Flag OH1", code: 'open_flag_oh1')
          .csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
          .csd_open_flag!
      oh_1_day_of_the_week_field = layer.numeric_fields.create!(ord: 14, name: "Day of Week OH1", code: 'day_of_week_oh1')
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
        .csd_day_of_the_week!
      oh_1_beginning_hour_field = layer.text_fields.create!(ord: 15, name: "Beginning Hour OH1", code: 'beginning_hour_oh1')
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
        .csd_beginning_hour!
      oh_1_ending_hour_field = layer.text_fields.create!(ord: 16, name: "Ending Hour OH1", code: 'ending_hour_oh1')
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
        .csd_ending_hour!
      oh_1_begin_effective_date_field = layer.text_fields.create!(ord: 17, name: "Begin Effective OH1", code: 'begin_effective_oh1')
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
        .csd_begin_effective_date!

      oh_2_open_flag_field = layer.yes_no_fields.create!(ord: 18, name: "Open Flag OH2", code: 'open_flag_oh2')
          .csd_operating_hours("OH2", Field::CSDApiConcern::csd_facility_tag)
          .csd_open_flag!
      oh_2_day_of_the_week_field = layer.numeric_fields.create!(ord: 19, name: "Day of Week OH2", code: 'day_of_week_oh2')
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_facility_tag)
        .csd_day_of_the_week!
      oh_2_beginning_hour_field = layer.text_fields.create!(ord: 20, name: "Beginning Hour OH2", code: 'beginning_hour_oh2')
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_facility_tag)
        .csd_beginning_hour!
      oh_2_ending_hour_field = layer.text_fields.create!(ord: 21, name: "Ending Hour OH2", code: 'ending_hour_oh2')
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_facility_tag)
        .csd_ending_hour!
      oh_2_begin_effective_date_field = layer.text_fields.create!(ord: 22, name: "Begin Effective OH2", code: 'begin_effective_oh2')
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_facility_tag)
        .csd_begin_effective_date!

      oh_3_open_flag_field = layer.yes_no_fields.create!(ord: 23, name: "Open Flag OH3", code: 'open_flag_oh3')
          .csd_operating_hours("OH3", Field::CSDApiConcern::csd_facility_tag)
          .csd_open_flag!
      oh_3_day_of_the_week_field = layer.numeric_fields.create!(ord: 24, name: "Day of Week OH3", code: 'day_of_week_oh3')
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_facility_tag)
        .csd_day_of_the_week!
      oh_3_beginning_hour_field = layer.text_fields.create!(ord: 25, name: "Beginning Hour OH3", code: 'beginning_hour_oh3')
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_facility_tag)
        .csd_beginning_hour!
      oh_3_ending_hour_field = layer.text_fields.create!(ord: 26, name: "Ending Hour OH3", code: 'ending_hour_oh3')
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_facility_tag)
        .csd_ending_hour!
      oh_3_begin_effective_date_field = layer.text_fields.create!(ord: 27, name: "Begin Effective OH3", code: 'begin_effective_oh3')
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_facility_tag)
        .csd_begin_effective_date!

      oh_4_open_flag_field = layer.yes_no_fields.create!(ord: 28, name: "Open Flag OH4", code: 'open_flag_oh4')
          .csd_operating_hours("OH4", Field::CSDApiConcern::csd_facility_tag)
          .csd_open_flag!
      oh_4_day_of_the_week_field = layer.numeric_fields.create!(ord: 29, name: "Day of Week OH4", code: 'day_of_week_oh4')
        .csd_operating_hours("OH4", Field::CSDApiConcern::csd_facility_tag)
        .csd_day_of_the_week!
      oh_4_beginning_hour_field = layer.text_fields.create!(ord: 30, name: "Beginning Hour OH4", code: 'beginning_hour_oh4')
        .csd_operating_hours("OH4", Field::CSDApiConcern::csd_facility_tag)
        .csd_beginning_hour!
      oh_4_ending_hour_field = layer.text_fields.create!(ord: 31, name: "Ending Hour OH4", code: 'ending_hour_oh4')
        .csd_operating_hours("OH4", Field::CSDApiConcern::csd_facility_tag)
        .csd_ending_hour!
      oh_4_begin_effective_date_field = layer.text_fields.create!(ord: 32, name: "Begin Effective OH4", code: 'begin_effective_oh4')
        .csd_operating_hours("OH4", Field::CSDApiConcern::csd_facility_tag)
        .csd_begin_effective_date!

      oh_5_open_flag_field = layer.yes_no_fields.create!(ord: 33, name: "Open Flag OH5", code: 'open_flag_oh5')
          .csd_operating_hours("OH5", Field::CSDApiConcern::csd_facility_tag)
          .csd_open_flag!
      oh_5_day_of_the_week_field = layer.numeric_fields.create!(ord: 34, name: "Day of Week OH5", code: 'day_of_week_oh5')
        .csd_operating_hours("OH5", Field::CSDApiConcern::csd_facility_tag)
        .csd_day_of_the_week!
      oh_5_beginning_hour_field = layer.text_fields.create!(ord: 35, name: "Beginning Hour OH5", code: 'beginning_hour_oh5')
        .csd_operating_hours("OH5", Field::CSDApiConcern::csd_facility_tag)
        .csd_beginning_hour!
      oh_5_ending_hour_field = layer.text_fields.create!(ord: 36, name: "Ending Hour OH5", code: 'ending_hour_oh5')
        .csd_operating_hours("OH5", Field::CSDApiConcern::csd_facility_tag)
        .csd_ending_hour!
      oh_5_begin_effective_date_field = layer.text_fields.create!(ord: 37, name: "Begin Effective OH5", code: 'begin_effective_oh5')
        .csd_operating_hours("OH5", Field::CSDApiConcern::csd_facility_tag)
        .csd_begin_effective_date!

      # TODO: Refactor
      billing_address_street_field = layer.text_fields.create!(ord: 38, name: "Billing Address Street", code: "billing_address_street",
          metadata: {"0"=>{"key"=>"CSDAddress", "value"=>"CSDAddress"}, "1"=>{"key"=>"CSDComponent", "value"=>"streetAddress"}, "2"=>{"key"=>"CSDCode", "value"=>"Billing"}, "3"=> {"key"=> "CSDChildOf", "value" => "CSDFacility"}})
      billing_address_city_field = layer.text_fields.create!(ord: 39, name: "Billing Address City", code: "billing_address_city",
          metadata: {"0"=>{"key"=>"CSDAddress", "value"=>"CSDAddress"}, "1"=>{"key"=>"CSDComponent", "value"=>"city"}, "2"=>{"key"=>"CSDCode", "value"=>"Billing"}, "3"=> {"key"=> "CSDChildOf", "value" => "CSDFacility"}})
      billing_address_state_field = layer.text_fields.create!(ord: 40, name: "Billing Address stateProvince", code: "billing_address_state_province",
          metadata: {"0"=>{"key"=>"CSDAddress", "value"=>"CSDAddress"}, "1"=>{"key"=>"CSDComponent", "value"=>"stateProvince"}, "2"=>{"key"=>"CSDCode", "value"=>"Billing"}, "3"=> {"key"=> "CSDChildOf", "value" => "CSDFacility"}})
      billing_address_country_field = layer.text_fields.create!(ord: 41, name: "Billing Address Country", code: "billing_address_state_country",
          metadata: {"0"=>{"key"=>"CSDAddress", "value"=>"CSDAddress"}, "1"=>{"key"=>"CSDComponent", "value"=>"country"}, "2"=>{"key"=>"CSDCode", "value"=>"Billing"}, "3"=> {"key"=> "CSDChildOf", "value" => "CSDFacility"}})
      billing_address_postal_code_field = layer.text_fields.create!(ord: 42, name: "Billing Address PostalCode", code: "billing_address_state_postal_code",
          metadata: {"0"=>{"key"=>"CSDAddress", "value"=>"CSDAddress"}, "1"=>{"key"=>"CSDComponent", "value"=>"postalCode"}, "2"=>{"key"=>"CSDCode", "value"=>"Billing"}, "3"=> {"key"=> "CSDChildOf", "value" => "CSDFacility"}})

      practice_address_street_field = layer.text_fields.create!(ord: 43, name: "Practice Address Street", code: "practice_address_street",
          metadata: {"0"=>{"key"=>"CSDAddress", "value"=>"CSDAddress"}, "1"=>{"key"=>"CSDComponent", "value"=>"streetAddress"}, "2"=>{"key"=>"CSDCode", "value"=>"Practice"}, "3"=> {"key"=> "CSDChildOf", "value" => "CSDFacility"}})
      practice_address_city_field = layer.text_fields.create!(ord: 44, name: "Practice Address City", code: "practice_address_city",
          metadata: {"0"=>{"key"=>"CSDAddress", "value"=>"CSDAddress"}, "1"=>{"key"=>"CSDComponent", "value"=>"city"}, "2"=>{"key"=>"CSDCode", "value"=>"Practice"}, "3"=> {"key"=> "CSDChildOf", "value" => "CSDFacility"}})

      practice_address_state_field = layer.text_fields.create!(ord: 45, name: "Practice Address stateProvince", code: "practice_address_state_province",
          metadata: {"0"=>{"key"=>"CSDAddress", "value"=>"CSDAddress"}, "1"=>{"key"=>"CSDComponent", "value"=>"stateProvince"}, "2"=>{"key"=>"CSDCode", "value"=>"Practice"}, "3"=> {"key"=> "CSDChildOf", "value" => "CSDFacility"}})

      practice_address_country_field = layer.text_fields.create!(ord: 46, name: "Practice Address Country", code: "practice_address_state_country",
          metadata: {"0"=>{"key"=>"CSDAddress", "value"=>"CSDAddress"}, "1"=>{"key"=>"CSDComponent", "value"=>"country"}, "2"=>{"key"=>"CSDCode", "value"=>"Practice"}, "3"=> {"key"=> "CSDChildOf", "value" => "CSDFacility"}})
      practice_address_postal_code_field = layer.text_fields.create!(ord: 47, name: "Practice Address PostalCode", code: "practice_address_state_postal_code",
          metadata: {"0"=>{"key"=>"CSDAddress", "value"=>"CSDAddress"}, "1"=>{"key"=>"CSDComponent", "value"=>"postalCode"}, "2"=>{"key"=>"CSDCode", "value"=>"Practice"}, "3"=> {"key"=> "CSDChildOf", "value" => "CSDFacility"}})

      organization_1_field = layer.text_fields.create!(ord: 48, name: "Organization 1", code: "org_1")
        .csd_organization("Org1").csd_oid!(Field::CSDApiConcern::csd_organization_tag)

      service_1_field = layer.text_fields.create!(ord: 49, name: "Service 1", code: "service_1")
        .csd_organization("Org1").csd_service!("Service 1").csd_oid!(Field::CSDApiConcern::csd_service_tag)
      service_1_name_field = layer.text_fields.create!(ord: 50, name: "Service 1 Name", code: "service_1_name")
        .csd_organization("Org1").csd_service!("Service 1").csd_name!("name1", Field::CSDApiConcern::csd_service_tag)
      service_1_language_field = layer.select_one_fields.create!(ord: 51, name: "Service 1 Language", code: "service_1_language", config: language_config)
        .csd_organization("Org1").csd_service!("Service 1").csd_language!("BCP 47", Field::CSDApiConcern::csd_service_tag)

      service_2_field = layer.text_fields.create!(ord: 52, name: "Service 2", code: "service_2")
        .csd_organization("Org1").csd_service!("Service 2").csd_oid!(Field::CSDApiConcern::csd_service_tag)
      service_2_name_field = layer.text_fields.create!(ord: 53, name: "Service 2 Name", code: "service_2_name")
        .csd_organization("Org1").csd_service!("Service 2").csd_name!("name1", Field::CSDApiConcern::csd_service_tag)
      service_2_language_field = layer.select_one_fields.create!(ord: 54, name: "Service 2 Language", code: "service_2_language", config: language_config)
        .csd_organization("Org1").csd_service!("Service 2").csd_language!("BCP 47", Field::CSDApiConcern::csd_service_tag)

      service_3_field = layer.text_fields.create!(ord: 55, name: "Service 3", code: "service_3")
        .csd_organization("Org1").csd_service!("Service 3").csd_oid!(Field::CSDApiConcern::csd_service_tag)
      service_3_name_field = layer.text_fields.create!(ord: 56, name: "Service 3 Name", code: "service_3_name")
        .csd_organization("Org1").csd_service!("Service 3").csd_name!("name3", Field::CSDApiConcern::csd_service_tag)
      service_3_language_field = layer.select_one_fields.create!(ord: 57, name: "Service 3 Language", code: "service_3_language", config: language_config)
        .csd_organization("Org1").csd_service!("Service 3").csd_language!("BCP 47", Field::CSDApiConcern::csd_service_tag)

      service_4_field = layer.text_fields.create!(ord: 58, name: "Service 4", code: "service_4")
        .csd_organization("Org1").csd_service!("Service 4").csd_oid!(Field::CSDApiConcern::csd_service_tag)
      service_4_name_field = layer.text_fields.create!(ord: 59, name: "Service 4 Name", code: "service_4_name")
        .csd_organization("Org1").csd_service!("Service 4").csd_name!("name4", Field::CSDApiConcern::csd_service_tag)
      service_4_language_field = layer.select_one_fields.create!(ord: 60, name: "Service 4 Language", code: "service_4_language", config: language_config)
        .csd_organization("Org1").csd_service!("Service 4").csd_language!("BCP 47", Field::CSDApiConcern::csd_service_tag)

      service_1_oh_1_open_flag_field = layer.yes_no_fields.create!(ord: 61, name: "Service 1 Operating Hour 1 Open Flag", code: 'service_1_open_flag_oh1')
          .csd_organization("Org1").csd_service!("Service 1")
          .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_1_oh_1_day_of_the_week_field = layer.numeric_fields.create!(ord: 62, name: "Service 1 Day of Week OH1", code: 'service_1_day_of_week_oh1')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_1_oh_1_beginning_hour_field = layer.text_fields.create!(ord: 63, name: "Service 1Beginning Hour OH1", code: 'service_1_beginning_hour_oh1')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_1_oh_1_ending_hour_field = layer.text_fields.create!(ord: 64, name: "Service 1 Ending Hour OH1", code: 'service_1_ending_hour_oh1')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_1_oh_1_begin_effective_date_field = layer.text_fields.create!(ord: 65, name: "Service 1Begin Effective OH1", code: 'service_1_begin_effective_oh1')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


      service_1_oh_2_open_flag_field = layer.yes_no_fields.create!(ord: 66, name: "Service 1 Operating Hour 2 Open Flag", code: 'service_1_open_flag_oh2')
          .csd_organization("Org1").csd_service!("Service 1")
          .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_1_oh_2_day_of_the_week_field = layer.numeric_fields.create!(ord: 67, name: "Service 1 Day of Week OH2", code: 'service_1_day_of_week_oh2')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_1_oh_2_beginning_hour_field = layer.text_fields.create!(ord: 68, name: "Service 1Beginning Hour OH2", code: 'service_1_beginning_hour_oh2')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_1_oh_2_ending_hour_field = layer.text_fields.create!(ord: 69, name: "Service 1 Ending Hour OH2", code: 'service_1_ending_hour_oh2')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_1_oh_2_begin_effective_date_field = layer.text_fields.create!(ord: 70, name: "Service 1 Begin Effective OH2", code: 'service_1_begin_effective_oh2')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!

      service_1_oh_3_open_flag_field = layer.yes_no_fields.create!(ord: 71, name: "Service 1 Operating Hour 3 Open Flag", code: 'service_1_open_flag_oh3')
          .csd_organization("Org1").csd_service!("Service 1")
          .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_1_oh_3_day_of_the_week_field = layer.numeric_fields.create!(ord: 72, name: "Service 1 Day of Week OH3", code: 'service_1_day_of_week_oh3')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_1_oh_3_beginning_hour_field = layer.text_fields.create!(ord: 73, name: "Service 1Beginning Hour OH3", code: 'service_1_beginning_hour_oh3')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_1_oh_3_ending_hour_field = layer.text_fields.create!(ord: 74, name: "Service 1 Ending Hour OH3", code: 'service_1_ending_hour_oh3')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_1_oh_3_begin_effective_date_field = layer.text_fields.create!(ord: 75, name: "Service 1 Begin Effective OH3", code: 'service_1_begin_effective_oh3')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


      service_2_oh_1_open_flag_field = layer.yes_no_fields.create!(ord: 76, name: "Service 2 Operating Hour 1 Open Flag", code: 'service_2_open_flag_oh1')
          .csd_organization("Org1").csd_service!("Service 2")
          .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_2_oh_1_day_of_the_week_field = layer.numeric_fields.create!(ord: 77, name: "Service 2 Day of Week OH1", code: 'service_2_day_of_week_oh1')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_2_oh_1_beginning_hour_field = layer.text_fields.create!(ord: 78, name: "Service 2Beginning Hour OH1", code: 'service_2_beginning_hour_oh1')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_2_oh_1_ending_hour_field = layer.text_fields.create!(ord: 79, name: "Service 2 Ending Hour OH1", code: 'service_2_ending_hour_oh1')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_2_oh_1_begin_effective_date_field = layer.text_fields.create!(ord: 80, name: "Service 2 Begin Effective OH1", code: 'service_2_begin_effective_oh1')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


      service_2_oh_2_open_flag_field = layer.yes_no_fields.create!(ord: 81, name: "Service 2 Operating Hour 2 Open Flag", code: 'service_2_open_flag_oh2')
          .csd_organization("Org1").csd_service!("Service 2")
          .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_2_oh_2_day_of_the_week_field = layer.numeric_fields.create!(ord: 82, name: "Service 2 Day of Week OH2", code: 'service_2_day_of_week_oh2')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_2_oh_2_beginning_hour_field = layer.text_fields.create!(ord: 83, name: "Service 2 Beginning Hour OH2", code: 'service_2_beginning_hour_oh2')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_2_oh_2_ending_hour_field = layer.text_fields.create!(ord: 84, name: "Service 2 Ending Hour OH2", code: 'service_2_ending_hour_oh2')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_2_oh_2_begin_effective_date_field = layer.text_fields.create!(ord: 85, name: "Service 2 Begin Effective OH2", code: 'service_2_begin_effective_oh2')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!

      service_2_oh_3_open_flag_field = layer.yes_no_fields.create!(ord: 86, name: "Service 2 Operating Hour 3 Open Flag", code: 'service_2_open_flag_oh3')
          .csd_organization("Org1").csd_service!("Service 2")
          .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_2_oh_3_day_of_the_week_field = layer.numeric_fields.create!(ord: 87, name: "Service 2 Day of Week OH3", code: 'service_2_day_of_week_oh3')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_2_oh_3_beginning_hour_field = layer.text_fields.create!(ord: 88, name: "Service 2Beginning Hour OH3", code: 'service_2_beginning_hour_oh3')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_2_oh_3_ending_hour_field = layer.text_fields.create!(ord: 89, name: "Service 2 Ending Hour OH3", code: 'service_2_ending_hour_oh3')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_2_oh_3_begin_effective_date_field = layer.text_fields.create!(ord: 92, name: "Service 2 Begin Effective OH3", code: 'service_2_begin_effective_oh3')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


      service_3_oh_1_open_flag_field = layer.yes_no_fields.create!(ord: 93, name: "Service 3 Operating Hour 1 Open Flag", code: 'service_3_open_flag_oh1')
          .csd_organization("Org1").csd_service!("Service 3")
          .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_3_oh_1_day_of_the_week_field = layer.numeric_fields.create!(ord: 94, name: "Service 3 Day of Week OH1", code: 'service_3_day_of_week_oh1')
        .csd_organization("Org1").csd_service!("Service 3")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_3_oh_1_beginning_hour_field = layer.text_fields.create!(ord: 95, name: "Service 3 Beginning Hour OH1", code: 'service_3_beginning_hour_oh1')
        .csd_organization("Org1").csd_service!("Service 3")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_3_oh_1_ending_hour_field = layer.text_fields.create!(ord: 96, name: "Service 3 Ending Hour OH1", code: 'service_3_ending_hour_oh1')
        .csd_organization("Org1").csd_service!("Service 3")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_3_oh_1_begin_effective_date_field = layer.text_fields.create!(ord: 97, name: "Service 3 Begin Effective OH1", code: 'service_3_begin_effective_oh1')
        .csd_organization("Org1").csd_service!("Service 3")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


      service_3_oh_2_open_flag_field = layer.yes_no_fields.create!(ord: 98, name: "Service 3 Operating Hour 2 Open Flag", code: 'service_3_open_flag_oh2')
          .csd_organization("Org1").csd_service!("Service 3")
          .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_3_oh_2_day_of_the_week_field = layer.numeric_fields.create!(ord: 99, name: "Service 3 Day of Week OH2", code: 'service_3_day_of_week_oh2')
        .csd_organization("Org1").csd_service!("Service 3")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_3_oh_2_beginning_hour_field = layer.text_fields.create!(ord: 100, name: "Service 3 Beginning Hour OH2", code: 'service_3_beginning_hour_oh2')
        .csd_organization("Org1").csd_service!("Service 3")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_3_oh_2_ending_hour_field = layer.text_fields.create!(ord: 101, name: "Service 3 Ending Hour OH2", code: 'service_3_ending_hour_oh2')
        .csd_organization("Org1").csd_service!("Service 3")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_3_oh_2_begin_effective_date_field = layer.text_fields.create!(ord: 102, name: "Service 3 Begin Effective OH2", code: 'service_3_begin_effective_oh2')
        .csd_organization("Org1").csd_service!("Service 3")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


      service_4_oh_2_open_flag_field = layer.yes_no_fields.create!(ord: 103, name: "Service 4 Operating Hour 2 Open Flag", code: 'service_4_open_flag_oh2')
          .csd_organization("Org1").csd_service!("Service 4")
          .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_4_oh_2_day_of_the_week_field = layer.numeric_fields.create!(ord: 104, name: "Service 4 Day of Week OH2", code: 'service_4_day_of_week_oh2')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_4_oh_2_beginning_hour_field = layer.text_fields.create!(ord: 105, name: "Service 4 Beginning Hour OH2", code: 'service_4_beginning_hour_oh2')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_4_oh_2_ending_hour_field = layer.text_fields.create!(ord: 106, name: "Service 4 Ending Hour OH2", code: 'service_4_ending_hour_oh2')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_4_oh_2_begin_effective_date_field = layer.text_fields.create!(ord: 107, name: "Service 4 Begin Effective OH2", code: 'service_4_begin_effective_oh2')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


     service_4_oh_1_open_flag_field = layer.yes_no_fields.create!(ord: 108, name: "Service 4 Operating Hour 1 Open Flag", code: 'service_4_open_flag_oh1')
          .csd_organization("Org1").csd_service!("Service 4")
          .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_4_oh_1_day_of_the_week_field = layer.numeric_fields.create!(ord: 109, name: "Service 4 Day of Week OH1", code: 'service_4_day_of_week_oh1')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_4_oh_1_beginning_hour_field = layer.text_fields.create!(ord: 110, name: "Service 4 Beginning Hour OH1", code: 'service_4_beginning_hour_oh1')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_4_oh_1_ending_hour_field = layer.text_fields.create!(ord: 111, name: "Service 4 Ending Hour OH1", code: 'service_4_ending_hour_oh1')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_4_oh_1_begin_effective_date_field = layer.text_fields.create!(ord: 112, name: "Service 4 Begin Effective OH1", code: 'service_4_begin_effective_oh1')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!

      service_4_oh_3_open_flag_field = layer.yes_no_fields.create!(ord: 113, name: "Service 4 Operating Hour 3 Open Flag", code: 'service_4_open_flag_oh3')
          .csd_organization("Org1").csd_service!("Service 4")
          .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_4_oh_3_day_of_the_week_field = layer.numeric_fields.create!(ord: 114, name: "Service 4 Day of Week OH3", code: 'service_4_day_of_week_oh3')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_4_oh_3_beginning_hour_field = layer.text_fields.create!(ord: 115, name: "Service 4 Beginning Hour OH3", code: 'service_4_beginning_hour_oh3')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_4_oh_3_ending_hour_field = layer.text_fields.create!(ord: 116, name: "Service 4 Ending Hour OH3", code: 'service_4_ending_hour_oh3')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_4_oh_3_begin_effective_date_field = layer.text_fields.create!(ord: 117, name: "Service 4 Begin Effective OH3", code: 'service_4_begin_effective_oh3')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


      service_4_oh_4_open_flag_field = layer.yes_no_fields.create!(ord: 118, name: "Service 4 Operating Hour 4 Open Flag", code: 'service_4_open_flag_oh4')
          .csd_organization("Org1").csd_service!("Service 4")
          .csd_operating_hours("OH4", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_4_oh_4_day_of_the_week_field = layer.numeric_fields.create!(ord: 119, name: "Service 4 Day of Week OH4", code: 'service_4_day_of_week_oh4')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH4", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_4_oh_4_beginning_hour_field = layer.text_fields.create!(ord: 120, name: "Service 4 Beginning Hour OH4", code: 'service_4_beginning_hour_oh4')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH4", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_4_oh_4_ending_hour_field = layer.text_fields.create!(ord: 121, name: "Service 4 Ending Hour OH4", code: 'service_4_ending_hour_oh4')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH4", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_4_oh_4_begin_effective_date_field = layer.text_fields.create!(ord: 122, name: "Service 4 Begin Effective OH4", code: 'service_4_begin_effective_oh4')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH4", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!



      service_4_oh_5_open_flag_field = layer.yes_no_fields.create!(ord: 123, name: "Service 4 Operating Hour 5 Open Flag", code: 'service_4_open_flag_oh5')
          .csd_organization("Org1").csd_service!("Service 4")
          .csd_operating_hours("OH5", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_4_oh_5_day_of_the_week_field = layer.numeric_fields.create!(ord: 124, name: "Service 4 Day of Week OH5", code: 'service_4_day_of_week_oh5')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH5", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_4_oh_5_beginning_hour_field = layer.text_fields.create!(ord: 125, name: "Service 4 Beginning Hour OH5", code: 'service_4_beginning_hour_oh5')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH5", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_4_oh_5_ending_hour_field = layer.text_fields.create!(ord: 126, name: "Service 4 Ending Hour OH5", code: 'service_4_ending_hour_oh5')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH5", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_4_oh_5_begin_effective_date_field = layer.text_fields.create!(ord: 127, name: "Service 4 Begin Effective OH5", code: 'service_4_begin_effective_oh5')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH5", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!

      service_4_oh_6_open_flag_field = layer.yes_no_fields.create!(ord: 123, name: "Service 4 Operating Hour 6 Open Flag", code: 'service_4_open_flag_oh6')
          .csd_organization("Org1").csd_service!("Service 4")
          .csd_operating_hours("OH6", Field::CSDApiConcern::csd_service_tag)
          .csd_open_flag!
      service_4_oh_6_day_of_the_week_field = layer.numeric_fields.create!(ord: 124, name: "Service 4 Day of Week OH6", code: 'service_4_day_of_week_oh6')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH6", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
      service_4_oh_6_beginning_hour_field = layer.text_fields.create!(ord: 125, name: "Service 4 Beginning Hour OH6", code: 'service_4_beginning_hour_oh6')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH6", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
      service_4_oh_6_ending_hour_field = layer.text_fields.create!(ord: 126, name: "Service 4 Ending Hour OH6", code: 'service_4_ending_hour_oh6')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH6", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
      service_4_oh_6_begin_effective_date_field = layer.text_fields.create!(ord: 127, name: "Service 4 Begin Effective OH6", code: 'service_4_begin_effective_oh6')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH6", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


      stub_time Time.iso8601("2014-12-01T14:00:00-00:00").to_s
      site_a = collection.sites.create!(name: 'Connectathon Radiology Facility', lat: 35.05, lng: 106.60, user: user,
        properties: {
          coded_type_medical_specialty.es_code => 1,
          entity_id_field.es_code => "1.3.6.1.4.1.21367.200.99.11",
          contact_1_common_name_field.es_code => "Anderson, Andrew",
          contact_1_forename_field.es_code => "Andrew",
          contact_1_surname_field.es_code => "Anderson",
          contact_1_street_address_field.es_code => "2222 19th Ave SW",
          contact_1_city_field.es_code => "Santa Fe",
          contact_1_state_province_field.es_code => "NM",
          contact_1_country_field.es_code => "USA",
          contact_1_postal_code_field.es_code => "87124",

          contact_2_common_name_field.es_code => "Juarez, Julio",
          contact_2_forename_field.es_code => "Julio",
          contact_2_surname_field.es_code => "Juarez",
          contact_2_street_address_field.es_code => "2222 19th Ave SW",
          contact_2_city_field.es_code => "Santa Fe",
          contact_2_state_province_field.es_code => "NM",
          contact_2_country_field.es_code => "USA",
          contact_2_postal_code_field.es_code => "87124",

          language_1_field.es_code => 1,
          language_2_field.es_code => 2,

          oh_1_open_flag_field.es_code => true,
          oh_1_day_of_the_week_field.es_code => 1,
          oh_1_beginning_hour_field.es_code => '08:00:00',
          oh_1_ending_hour_field.es_code => '18:00:00',
          oh_1_begin_effective_date_field.es_code => '2014-12-01',

          oh_2_open_flag_field.es_code => true,
          oh_2_day_of_the_week_field.es_code => 2,
          oh_2_beginning_hour_field.es_code => '13:00:00',
          oh_2_ending_hour_field.es_code => '17:00:00',
          oh_2_begin_effective_date_field.es_code => '2014-12-01',

          oh_3_open_flag_field.es_code => true,
          oh_3_day_of_the_week_field.es_code => 3,
          oh_3_beginning_hour_field.es_code => '09:00:00',
          oh_3_ending_hour_field.es_code => '17:00:00',
          oh_3_begin_effective_date_field.es_code => '2014-12-01',

          oh_4_open_flag_field.es_code => true,
          oh_4_day_of_the_week_field.es_code => 4,
          oh_4_beginning_hour_field.es_code => '13:00:00',
          oh_4_ending_hour_field.es_code => '17:00:00',
          oh_4_begin_effective_date_field.es_code => '2014-12-01',

          oh_5_open_flag_field.es_code => true,
          oh_5_day_of_the_week_field.es_code => 5,
          oh_5_beginning_hour_field.es_code => '09:00:00',
          oh_5_ending_hour_field.es_code => '17:00:00',
          oh_5_begin_effective_date_field.es_code => '2013-12-01',

          billing_address_street_field.es_code => "1234 Cactus Way",
          billing_address_city_field.es_code => 'Santa Fe',
          billing_address_state_field.es_code => "NM",
          billing_address_country_field.es_code => "USA",
          billing_address_postal_code_field.es_code => "87501",

          practice_address_street_field.es_code => "2222 19th Ave SW",
          practice_address_city_field.es_code => 'Santa Fe',
          practice_address_state_field.es_code => "NM",
          practice_address_country_field.es_code => "USA",
          practice_address_postal_code_field.es_code => "87124",

          organization_1_field.es_code => "1.3.6.1.4.1.21367.200.99.1",

          service_1_field.es_code => "1.3.6.1.4.1.21367.200.99.111.101.102",
          service_1_name_field.es_code => "Connectathon Radiation Therapy",
          service_1_language_field.es_code => 1,

          service_1_oh_1_open_flag_field.es_code => true,
          service_1_oh_1_day_of_the_week_field.es_code => 1,
          service_1_oh_1_beginning_hour_field.es_code => '09:00:00',
          service_1_oh_1_ending_hour_field.es_code => '12:00:00',
          service_1_oh_1_begin_effective_date_field.es_code => '2014-12-01',

          service_1_oh_2_open_flag_field.es_code => true,
          service_1_oh_2_day_of_the_week_field.es_code => 3,
          service_1_oh_2_beginning_hour_field.es_code => '09:00:00',
          service_1_oh_2_ending_hour_field.es_code => '12:00:00',
          service_1_oh_2_begin_effective_date_field.es_code => '2014-12-01',

          service_1_oh_3_open_flag_field.es_code => true,
          service_1_oh_3_day_of_the_week_field.es_code => 5,
          service_1_oh_3_beginning_hour_field.es_code => '09:00:00',
          service_1_oh_3_ending_hour_field.es_code => '12:00:00',
          service_1_oh_3_begin_effective_date_field.es_code => '2014-12-01',

          service_2_field.es_code => "1.3.6.1.4.1.21367.200.99.111.101.113",
          service_2_name_field.es_code => "Connectathon Women's Imaging Service",
          service_2_language_field.es_code => 1,

          service_2_oh_1_open_flag_field.es_code => true,
          service_2_oh_1_day_of_the_week_field.es_code => 1,
          service_2_oh_1_beginning_hour_field.es_code => '13:00:00',
          service_2_oh_1_ending_hour_field.es_code => '17:00:00',
          service_2_oh_1_begin_effective_date_field.es_code => '2014-12-01',

          service_2_oh_2_open_flag_field.es_code => true,
          service_2_oh_2_day_of_the_week_field.es_code => 3,
          service_2_oh_2_beginning_hour_field.es_code => '13:00:00',
          service_2_oh_2_ending_hour_field.es_code => '17:00:00',
          service_2_oh_2_begin_effective_date_field.es_code => '2014-12-01',

          service_2_oh_3_open_flag_field.es_code => true,
          service_2_oh_3_day_of_the_week_field.es_code => 5,
          service_2_oh_3_beginning_hour_field.es_code => '13:00:00',
          service_2_oh_3_ending_hour_field.es_code => '17:00:00',
          service_2_oh_3_begin_effective_date_field.es_code => '2014-12-01',

          service_3_field.es_code => "1.3.6.1.4.1.21367.200.99.111.101.113",
          service_3_name_field.es_code => "Connectathon Servicio de Radiologica de la Mujer",
          service_3_language_field.es_code => 2,

          service_3_oh_1_open_flag_field.es_code => true,
          service_3_oh_1_day_of_the_week_field.es_code => 2,
          service_3_oh_1_beginning_hour_field.es_code => '13:00:00',
          service_3_oh_1_ending_hour_field.es_code => '17:00:00',
          service_3_oh_1_begin_effective_date_field.es_code => '2014-12-01',

          service_3_oh_2_open_flag_field.es_code => true,
          service_3_oh_2_day_of_the_week_field.es_code => 4,
          service_3_oh_2_beginning_hour_field.es_code => '13:00:00',
          service_3_oh_2_ending_hour_field.es_code => '17:00:00',
          service_3_oh_2_begin_effective_date_field.es_code => '2014-12-01',

          service_4_field.es_code => "1.3.6.1.4.1.21367.200.99.111.101.110",
          service_4_name_field.es_code => "Connectathon Screening X-ray",
          service_4_language_field.es_code => 1,

          service_4_oh_1_open_flag_field.es_code => true,
          service_4_oh_1_day_of_the_week_field.es_code => 1,
          service_4_oh_1_beginning_hour_field.es_code => '08:00:00',
          service_4_oh_1_ending_hour_field.es_code => '18:00:00',
          service_4_oh_1_begin_effective_date_field.es_code => '2014-12-01',

          service_4_oh_2_open_flag_field.es_code => true,
          service_4_oh_2_day_of_the_week_field.es_code => 2,
          service_4_oh_2_beginning_hour_field.es_code => '08:00:00',
          service_4_oh_2_ending_hour_field.es_code => '18:00:00',
          service_4_oh_2_begin_effective_date_field.es_code => '2014-12-01',

          service_4_oh_3_open_flag_field.es_code => true,
          service_4_oh_3_day_of_the_week_field.es_code => 3,
          service_4_oh_3_beginning_hour_field.es_code => '08:00:00',
          service_4_oh_3_ending_hour_field.es_code => '18:00:00',
          service_4_oh_3_begin_effective_date_field.es_code => '2014-12-01',

          service_4_oh_4_open_flag_field.es_code => true,
          service_4_oh_4_day_of_the_week_field.es_code => 4,
          service_4_oh_4_beginning_hour_field.es_code => '08:00:00',
          service_4_oh_4_ending_hour_field.es_code => '18:00:00',
          service_4_oh_4_begin_effective_date_field.es_code => '2014-12-01',

          service_4_oh_5_open_flag_field.es_code => true,
          service_4_oh_5_day_of_the_week_field.es_code => 5,
          service_4_oh_5_beginning_hour_field.es_code => '08:00:00',
          service_4_oh_5_ending_hour_field.es_code => '18:00:00',
          service_4_oh_5_begin_effective_date_field.es_code => '2014-12-01',

          service_4_oh_6_open_flag_field.es_code => true,
          service_4_oh_6_day_of_the_week_field.es_code => 6,
          service_4_oh_6_beginning_hour_field.es_code => '08:00:00',
          service_4_oh_6_ending_hour_field.es_code => '18:00:00',
          service_4_oh_6_begin_effective_date_field.es_code => '2014-12-01',
        })

      site_b = collection.sites.create!(name: 'Connectathon Dialysis Facility One', lat: 35.05, lng: 106.60, user: user,
        properties: {
          coded_type_medical_specialty.es_code => 2,
          entity_id_field.es_code => "1.3.6.1.4.1.21367.200.99.12",
          contact_1_common_name_field.es_code => "Benson, Barbara",
          contact_1_forename_field.es_code => "Barbara",
          contact_1_surname_field.es_code => "Benson",
          contact_1_street_address_field.es_code => "2222 19th Ave SW",
          contact_1_city_field.es_code => "Santa Fe",
          contact_1_state_province_field.es_code => "NM",
          contact_1_country_field.es_code => "USA",
          contact_1_postal_code_field.es_code => "87124",

          contact_2_common_name_field.es_code => "Martinez, Ruby",
          contact_2_forename_field.es_code => "Ruby",
          contact_2_surname_field.es_code => "Martinez",
          contact_2_street_address_field.es_code => "2222 19th Ave SW",
          contact_2_city_field.es_code => "Santa Fe",
          contact_2_state_province_field.es_code => "NM",
          contact_2_country_field.es_code => "USA",
          contact_2_postal_code_field.es_code => "87124",

          language_1_field.es_code => 1,
          language_2_field.es_code => 2,

          oh_1_open_flag_field.es_code => true,
          oh_1_day_of_the_week_field.es_code => 1,
          oh_1_beginning_hour_field.es_code => '08:00:00',
          oh_1_ending_hour_field.es_code => '17:00:00',
          oh_1_begin_effective_date_field.es_code => '2014-12-01',

          oh_5_open_flag_field.es_code => true,
          oh_5_day_of_the_week_field.es_code => 5,
          oh_5_beginning_hour_field.es_code => '05:00:00',
          oh_5_ending_hour_field.es_code => '17:00:00',
          oh_5_begin_effective_date_field.es_code => '2013-12-01',

          billing_address_street_field.es_code => "1234 Cactus Way",
          billing_address_city_field.es_code => 'Santa Fe',
          billing_address_state_field.es_code => "NM",
          billing_address_country_field.es_code => "USA",
          billing_address_postal_code_field.es_code => "87501",

          practice_address_street_field.es_code => "2222 19th Ave SW",
          practice_address_city_field.es_code => 'Rio Rancho',
          practice_address_state_field.es_code => "NM",
          practice_address_country_field.es_code => "USA",
          practice_address_postal_code_field.es_code => "87124",

          organization_1_field.es_code => "1.3.6.1.4.1.21367.200.99.1",

          service_1_field.es_code => "1.3.6.1.4.1.21367.200.99.111.101.104",
          service_1_name_field.es_code => "Connectathon Dialysis Service",
          service_1_language_field.es_code => 1,

          service_1_oh_1_open_flag_field.es_code => true,
          service_1_oh_1_day_of_the_week_field.es_code => 1,
          service_1_oh_1_beginning_hour_field.es_code => '09:00:00',
          service_1_oh_1_ending_hour_field.es_code => '17:00:00',
          service_1_oh_1_begin_effective_date_field.es_code => '2014-12-01',

          service_1_oh_2_open_flag_field.es_code => true,
          service_1_oh_2_day_of_the_week_field.es_code => 2,
          service_1_oh_2_beginning_hour_field.es_code => '09:00:00',
          service_1_oh_2_ending_hour_field.es_code => '17:00:00',
          service_1_oh_2_begin_effective_date_field.es_code => '2014-12-01',

          service_1_oh_3_open_flag_field.es_code => true,
          service_1_oh_3_day_of_the_week_field.es_code => 3,
          service_1_oh_3_beginning_hour_field.es_code => '09:00:00',
          service_1_oh_3_ending_hour_field.es_code => '17:00:00',
          service_1_oh_3_begin_effective_date_field.es_code => '2014-12-01',

          service_2_field.es_code => "1.3.6.1.4.1.21367.200.99.111.101.104",
          service_2_name_field.es_code => "Connectathon Diálisis Servicio",
          service_2_language_field.es_code => 2,

          service_2_oh_1_open_flag_field.es_code => true,
          service_2_oh_1_day_of_the_week_field.es_code => 4,
          service_2_oh_1_beginning_hour_field.es_code => '09:00:00',
          service_2_oh_1_ending_hour_field.es_code => '17:00:00',
          service_2_oh_1_begin_effective_date_field.es_code => '2015-01-01',

          service_2_oh_2_open_flag_field.es_code => true,
          service_2_oh_2_day_of_the_week_field.es_code => 5,
          service_2_oh_2_beginning_hour_field.es_code => '09:00:00',
          service_2_oh_2_ending_hour_field.es_code => '17:00:00',
          service_2_oh_2_begin_effective_date_field.es_code => '2015-01-01',
        })

      site_c = collection.sites.create!(name: 'Connectathon Dialysis Facility Two', lat: 34.5441, lng: 122.4717, user: user,
        properties: {
          coded_type_medical_specialty.es_code => 2,
          entity_id_field.es_code => "1.3.6.1.4.1.21367.200.99.13",
          contact_1_common_name_field.es_code => "Robertson, Robert",
          contact_1_forename_field.es_code => "Robert",
          contact_1_surname_field.es_code => "Robertson",
          contact_1_street_address_field.es_code => "2222 19th Ave SW",
          contact_1_city_field.es_code => "Santa Fe",
          contact_1_state_province_field.es_code => "NM",
          contact_1_country_field.es_code => "USA",
          contact_1_postal_code_field.es_code => "87124",

          contact_2_common_name_field.es_code => "Juarez, Angel",
          contact_2_forename_field.es_code => "Angel",
          contact_2_surname_field.es_code => "Juarez",
          contact_2_street_address_field.es_code => "2222 19th Ave SW",
          contact_2_city_field.es_code => "Santa Fe",
          contact_2_state_province_field.es_code => "NM",
          contact_2_country_field.es_code => "USA",
          contact_2_postal_code_field.es_code => "87124",

          language_1_field.es_code => 1,
          language_2_field.es_code => 2,

          oh_1_open_flag_field.es_code => true,
          oh_1_day_of_the_week_field.es_code => 1,
          oh_1_beginning_hour_field.es_code => '08:00:00',
          oh_1_ending_hour_field.es_code => '17:00:00',
          oh_1_begin_effective_date_field.es_code => '2014-12-01',

          oh_5_open_flag_field.es_code => true,
          oh_5_day_of_the_week_field.es_code => 5,
          oh_5_beginning_hour_field.es_code => '05:00:00',
          oh_5_ending_hour_field.es_code => '17:00:00',
          oh_5_begin_effective_date_field.es_code => '2014-12-01',

          billing_address_street_field.es_code => "434 W. Gurley Street",
          billing_address_city_field.es_code => 'Prescott',
          billing_address_state_field.es_code => "AZ",
          billing_address_country_field.es_code => "USA",
          billing_address_postal_code_field.es_code => "86301",

          practice_address_street_field.es_code => "434 W. Gurley Street",
          practice_address_city_field.es_code => 'Prescott',
          practice_address_state_field.es_code => "AZ",
          practice_address_country_field.es_code => "USA",
          practice_address_postal_code_field.es_code => "86301",

          organization_1_field.es_code => "1.3.6.1.4.1.21367.200.99.1",

          service_1_field.es_code => "1.3.6.1.4.1.21367.200.99.111.101.104",
          service_1_name_field.es_code => "Connectathon Diálisis Servicio",
          service_1_language_field.es_code => 2,

          service_1_oh_1_open_flag_field.es_code => true,
          service_1_oh_1_day_of_the_week_field.es_code => 5,
          service_1_oh_1_beginning_hour_field.es_code => '09:00:00',
          service_1_oh_1_ending_hour_field.es_code => '17:00:00',
          service_1_oh_1_begin_effective_date_field.es_code => '2014-12-01',

          service_4_field.es_code => "1.3.6.1.4.1.21367.200.99.111.101.104",
          service_4_name_field.es_code => "Connectathon Dialysis Service",
          service_4_language_field.es_code => 1,

          service_4_oh_1_open_flag_field.es_code => true,
          service_4_oh_1_day_of_the_week_field.es_code => 1,
          service_4_oh_1_beginning_hour_field.es_code => '09:00:00',
          service_4_oh_1_ending_hour_field.es_code => '17:00:00',
          service_4_oh_1_begin_effective_date_field.es_code => '2014-12-01',

          service_4_oh_2_open_flag_field.es_code => true,
          service_4_oh_2_day_of_the_week_field.es_code => 2,
          service_4_oh_2_beginning_hour_field.es_code => '09:00:00',
          service_4_oh_2_ending_hour_field.es_code => '17:00:00',
          service_4_oh_2_begin_effective_date_field.es_code => '2014-12-01',

          service_4_oh_3_open_flag_field.es_code => true,
          service_4_oh_3_day_of_the_week_field.es_code => 3,
          service_4_oh_3_beginning_hour_field.es_code => '09:00:00',
          service_4_oh_3_ending_hour_field.es_code => '17:00:00',
          service_4_oh_3_begin_effective_date_field.es_code => '2013-12-01',

          service_4_oh_4_open_flag_field.es_code => true,
          service_4_oh_4_day_of_the_week_field.es_code => 4,
          service_4_oh_4_beginning_hour_field.es_code => '09:00:00',
          service_4_oh_4_ending_hour_field.es_code => '17:00:00',
          service_4_oh_4_begin_effective_date_field.es_code => '2014-12-01',

          service_4_oh_5_open_flag_field.es_code => true,
          service_4_oh_5_day_of_the_week_field.es_code => 5,
          service_4_oh_5_beginning_hour_field.es_code => '09:00:00',
          service_4_oh_5_ending_hour_field.es_code => '17:00:00',
          service_4_oh_5_begin_effective_date_field.es_code => '2014-12-01',

          service_4_oh_6_open_flag_field.es_code => true,
          service_4_oh_6_day_of_the_week_field.es_code => 6,
          service_4_oh_6_beginning_hour_field.es_code => '09:00:00',
          service_4_oh_6_ending_hour_field.es_code => '17:00:00',
          service_4_oh_6_begin_effective_date_field.es_code => '2014-12-01',

        })

      request.env["RAW_POST_DATA"] = generate_request("urn:uuid:47b8c0c2-1eb1-4b4b-9605-19f091b64fb1", "2013-11-18T20:40:28-03:00")
      post :get_directory_modifications, collection_id: collection.id

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
