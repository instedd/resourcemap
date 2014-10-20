require 'spec_helper'

describe FredApiController, :type => :controller do
  include Devise::TestHelpers

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make) }
  let(:layer) { collection.layers.make }

  # We test only the field types supported by FRED API
  # Id fields are tested below
  let!(:text) { layer.text_fields.make :code => 'manager' }
  let!(:numeric) { layer.numeric_fields.make :code => 'numBeds'}
  let!(:select_many) { layer.select_many_fields.make :code => 'services', :config => {'options' => [{'id' => 1, 'code' => 'XR', 'label' => 'X-ray'}, {'id' => 2, 'code' => 'OBG', 'label' => 'Gynecology'}]} }
  let!(:date) { layer.date_fields.make :code => 'inagurationDay'}

  before(:each) { sign_in user }

  describe "GET facility" do

    let!(:site) { collection.sites.make }

    let!(:site_with_properties) { collection.sites.make :properties => {
      text.es_code => "Mrs. Liz",
      numeric.es_code => 55,
      select_many.es_code => [1, 2],
      date.es_code => "2012-10-24T00:00:00Z",
    }}

    it 'should get default fields' do
      get :show_facility, id: site.id, format: 'json', collection_id: collection.id
      expect(response).to be_ok
      expect(response.content_type).to eq 'application/json'

      json = JSON.parse response.body
      expect(json["name"]).to eq(site.name)
      expect(json["coordinates"][0]).to eq(site.lng)
      expect(json["coordinates"][1]).to eq(site.lat)
      expect(json['uuid']).to eq(site.uuid)
      expect(json["active"]).to eq(true)
      expect(json["href"]).to start_with("http://test.host/plugin/fred_api/collections/#{collection.id}/fred_api/v1/facilities/#{site.id}.json")

    end

    it 'should get extended properties' do
      get :show_facility, id: site_with_properties.id, format: 'json', collection_id: collection.id

      json = JSON.parse response.body
      expect(json["properties"].length).to eq(4)
      expect(json["properties"]['manager']).to eq("Mrs. Liz")
      expect(json["properties"]['numBeds']).to eq(55)
      expect(json["properties"]['services']).to eq(['XR', 'OBG'])
      expect(json["properties"]['inagurationDay']).to eq("2012-10-24T00:00:00Z")
    end

    it "should convert time in different timezone to UTC" do
      stub_time Time.iso8601("2013-02-04T20:25:27-03:00").to_s
      site2 = collection.sites.make name: 'Arg Site'
      get :show_facility, id: site2.id, format: 'json', collection_id: collection.id
      json = JSON.parse response.body
      expect(json["createdAt"]).to eq("2013-02-04T23:25:27Z")
    end

    it "should return valid UUID" do
      get :show_facility, id: site_with_properties.id, format: 'json', collection_id: collection.id
      json = JSON.parse response.body
      expect(json['uuid']).to be
      expect(json['uuid']).not_to be_empty
      expect(UUIDTools::UUID.parse json['uuid']).to be_valid
    end

  end

  describe "query list of facilities" do
    let!(:site1) { collection.sites.make name: 'Site A', properties:{ date.es_code => "2012-10-24T00:00:00Z"} }
    let!(:site2) { collection.sites.make name: 'Site B', properties:{ date.es_code => "2012-10-25T00:00:00Z"} }

    it 'should get the full list of facilities' do
      get :facilities, format: 'json', collection_id: collection.id
      expect(response).to be_success
      expect(response.content_type).to eq 'application/json'

      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(2)
    end

    it 'should sort the list of facilities by name asc' do
      get :facilities, format: 'json', sortAsc: 'name', collection_id: collection.id

      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(2)
      expect(json[0]["name"]).to eq(site1.name)
      expect(json[1]["name"]).to eq(site2.name)
    end

    it 'should sort the list of facilities by name desc' do
      get :facilities, format: 'json', sortDesc: 'name', collection_id: collection.id

      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(2)
      expect(json[0]["name"]).to eq(site2.name)
      expect(json[1]["name"]).to eq(site1.name)
    end

    it 'should sort the list of facilities by property date' do
      get :facilities, format: 'json', sortDesc: 'inagurationDay', collection_id: collection.id

      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(2)
      expect(json[0]["name"]).to eq(site2.name)
      expect(json[1]["name"]).to eq(site1.name)
    end

    describe 'limit' do
      (3..5).each do |i|
        let!("site#{i}".to_sym) { collection.sites.make name: "Site C#{i}", properties:{ date.es_code => "2012-10-26T00:00:00Z"} }
      end

      it 'should limit the number of facilities returned and the offset for the query' do
        get :facilities, format: 'json', limit: 1, collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        expect(json.length).to eq(1)
        expect(json[0]["name"]).to eq(site1.name)
        get :facilities, format: 'json', limit: 1, offset: 1, collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        expect(json.length).to eq(1)
        expect(json[0]["name"]).to eq(site2.name)
      end

      it 'should not limit the number of facilities when limit=off' do
        get :facilities, format: 'json', limit: "off", collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]

        # 3 sites created inside this test case, and 2 under "query list of facilities" describe scope
        expect(json.length).to eq(5)
      end
    end

    it 'should select only default fields' do
      get :facilities, format: 'json', fields: "name,updatedAt", collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(2)
      expect(json[0].length).to eq(2)
      expect(json[0]['name']).to eq(site1.name)
      iso_updated_at = Time.zone.parse(site1.updated_at.to_s).utc.iso8601
      expect(json[0]['updatedAt']).to eq(iso_updated_at)

      expect(json[1].length).to eq(2)
      expect(json[1]['name']).to eq(site2.name)
      iso_updated_at = Time.zone.parse(site2.updated_at.to_s).utc.iso8601
      expect(json[1]['updatedAt']).to eq(iso_updated_at)
    end

    it 'should select default and custom fields' do
      get :facilities, format: 'json', fields: "name,properties:inagurationDay", collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(2)
      expect(json[0].length).to eq(2)
      expect(json[0]['name']).to eq(site1.name)
      expect(json[0]['properties']['inagurationDay']).to eq("2012-10-24T00:00:00Z")

      expect(json[1].length).to eq(2)
      expect(json[1]['name']).to eq(site2.name)
      expect(json[1]['properties']['inagurationDay']).to eq("2012-10-25T00:00:00Z")
    end

    it 'should return all fields (default and custom) when parameter allProperties is set' do
      get :facilities, format: 'json', allProperties: true, collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(2)
      expect(json[0]['properties'].length).to eq(1)
      expect(json[1]['properties'].length).to eq(1)
    end

    it "should select uuid field in partial response" do
      get :facilities, format: 'json', fields: "uuid,properties:inagurationDay", collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(2)
      expect(json[0].length).to eq(2)
      expect(json[0]['uuid']).to eq(site1.uuid)
      expect(json[0]['properties']['inagurationDay']).to eq("2012-10-24T00:00:00Z")

      expect(json[1].length).to eq(2)
      expect(json[1]['uuid']).to eq(site2.uuid)
      expect(json[1]['properties']['inagurationDay']).to eq("2012-10-25T00:00:00Z")
    end

  end

  describe "Filtering Facilities" do
    let!(:site1) { collection.sites.make name: 'Site A', properties:{ numeric.es_code => 55} }
    let!(:site2) { collection.sites.make name: 'Site B', properties:{ numeric.es_code => 56} }


    it "should filter by name" do
      get :facilities, format: 'json', name: site1.name, collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(1)
      expect(json[0]['name']).to eq(site1.name)
    end

    it "should filter by coordinates" do
      get :facilities, format: 'json', coordinates: [site1.lng.to_f, site1.lat.to_f], collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(1)
      expect(json[0]['uuid']).to eq(site1.uuid)
    end

    it "should filter by updated_at" do
      Timecop.travel(3.seconds.from_now)
      site3 = collection.sites.make name: 'Site C'
      iso_updated_at = Time.zone.parse(site3.updated_at.to_s).utc.iso8601
      get :facilities, format: 'json', updatedAt: iso_updated_at, collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(1)
      expect(json[0]['uuid']).to eq(site3.uuid)
    end

    it "should filter by created_at" do
      Timecop.travel(3.seconds.from_now)
      site3 = collection.sites.make name: 'Site C'
      iso_created_at = Time.zone.parse(site3.created_at.to_s).utc.iso8601
      get :facilities, format: 'json', createdAt: iso_created_at, collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(1)
      expect(json[0]['uuid']).to eq(site3.uuid)
    end

    it "should filter by active" do
      #All ResourceMap facilities are active, because ResourceMap does not implement logical deletion yet
      get :facilities, format: 'json', active: 'false', collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(0)
    end

    it "should filter by updated since" do
      Timecop.travel(3.seconds.from_now)
      iso_before_update = Time.zone.now.utc.iso8601
      site1.name = "Site A New"
      site1.save!
      get :facilities, format: 'json', updatedSince: iso_before_update, collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(1)
      expect(json[0]['uuid']).to eq(site1.uuid)
    end

    it "should filter by updated since with miliseconds" do
      Timecop.travel(3.seconds.from_now)
      iso_before_update = Time.zone.now.utc.iso8601 5
      site1.name = "Site A New"
      site1.save!
      get :facilities, format: 'json', updatedSince: iso_before_update, collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(1)
      expect(json[0]['uuid']).to eq(site1.uuid)
    end

    it "should filter by updated since with arbitrary updated_at velues" do
      site1.destroy
      site2.destroy
      stub_time Time.iso8601("2013-02-04T21:25:27Z").to_s
      site3 = collection.sites.make name: 'Site C'
      stub_time Time.iso8601("2013-02-04T22:55:53Z").to_s
      site4 = collection.sites.make name: 'Site D'
      stub_time Time.iso8601("2013-02-04T22:55:59Z").to_s
      site5 = collection.sites.make name: 'Site E'
      get :facilities, format: 'json', updatedSince: "2013-02-04T22:55:53Z", collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(2)
      expect(json[0]['uuid']).to eq(site4.uuid)
      expect(json[1]['uuid']).to eq(site5.uuid)
    end

    it "should filter by property with 'properties.' prefix" do
      get :facilities, format: 'json', "properties.numBeds" => 55, collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(1)
      expect(json[0]['name']).to eq(site1.name)
    end

    it "should filter by uuid" do
      get :facilities, format: 'json', uuid: site1.uuid, collection_id: collection.id
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(1)
      expect(json[0]['uuid']).to eq(site1.uuid)
    end

  end

  describe "delete facility" do
    it "should render json's code field 200 when deleting a facility" do
      site = collection.sites.make name: 'Site C'
      delete :delete_facility, id: site.id, collection_id: collection.id
      json = JSON.parse response.body
      expect(json["code"]).to eq(200)
      expect(json["id"]).to eq(site.id.to_s)
      expect(json["message"]).to eq("Resource deleted")
      sites = Site.find_by_name 'Site C'
      expect(sites).to be(nil)
    end

    it "should render json's code field 404 when the site is not found in an empty collection" do
      expect(Site.count).to eq(0)
      delete :delete_facility, id: 100, collection_id: collection.id
      json = JSON.parse response.body
      expect(json["code"]).to eq("404 Not Found")
      expect(json["message"]).to eq("Resource not found")
    end

    let(:collection2) { user.create_collection(Collection.make) }

    it "should render 404 when a site of other collection is passed as parameter" do
      site = collection2.sites.make name: 'Site D'
      delete :delete_facility, id: site.id, collection_id: collection.id
      json = JSON.parse response.body
      expect(json["code"]).to eq("404 Not Found")
      expect(json["message"]).to eq("Resource not found")
    end

  end

  describe "http status codes" do
    let!(:site) { collection.sites.make }
    it "should return 200 in a valid request" do
      get :show_facility, id: site.id, format: 'json', collection_id: collection.id
      expect(response).to be_success
    end

    it "should return 401 if the user is not signed_in" do
      sign_out user
      get :show_facility, id: site.id, format: 'json', collection_id: collection.id
      expect(response.status).to eq(401)
    end

    it "should return 401 if the user is not signed_in" do
      sign_out user
      get :show_facility, id: site.id, format: 'json', collection_id: collection.id
      expect(response.status).to eq(401)
    end

    it "should return 403 if user is do not have permission to access the site" do
      user2 = User.make
      sign_out user
      sign_in user2
      get :show_facility, id: site.id, format: 'json', collection_id: collection.id
      expect(response.status).to eq(403)
    end

    it "should return 403 if user is do not have permission to access the collection" do
      collection2 = Collection.make
      get :show_facility, id: site.id, format: 'json', collection_id: collection2.id
      expect(response.status).to eq(403)
    end

    it "should return 409 if the site do not belong to the collection" do
      collection2 = Collection.make
      user.create_collection(collection2)
      get :show_facility, id: site.id, format: 'json', collection_id: collection2.id
      expect(response.status).to eq(409)
    end

    it "should return 404 if the requested site does not exist" do
      get :show_facility, id: 12355259, format: 'json', collection_id: collection.id
      expect(response.status).to eq(404)
      json = JSON.parse response.body
      expect(json['code']).to eq('404 Not Found')
      expect(json['message']).to eq('Resource not found')
    end

    it "should return 400 if a non existing field is included in the query" do
      get :facilities, format: 'json', invalid: "option", collection_id: collection.id
      expect(response.status).to eq(400)
    end
  end

  describe "should update facility" do
    let!(:site) { collection.sites.make :name => "Kakamega HC", :properties => {
      text.es_code => "Mrs. Liz",
      numeric.es_code => 55,
      select_many.es_code => [1, 2],
      date.es_code => "2012-10-24T00:00:00Z",
    }}

    it "should return 404 if the facility does not exist" do
      put :update_facility, collection_id: collection.id, id: "124566", :name => "Kakamega HC 2"
      expect(response.status).to eq(404)
    end

    it "should update name" do
      request.env["RAW_POST_DATA"] = { :name => "Kakamega HC 2" }.to_json
      put :update_facility, collection_id: collection.id, id: site.id
      expect(response.status).to eq(200)
      updated_site = Site.find site.id
      expect(updated_site.name).to eq("Kakamega HC 2")
    end

    it "should return 400 if id, url, createdAt or updatedAt are present in the query params" do
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', url: "sda" }.to_json
      put :update_facility, collection_id: collection.id, id: site.id
      expect(response.status).to eq(400)

      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', createdAt: "sda" }.to_json
      put :update_facility, collection_id: collection.id, id: site.id
      expect(response.status).to eq(400)

      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', updatedAt: "sda" }.to_json
      put :update_facility, collection_id: collection.id, id: site.id
      expect(response.status).to eq(400)
    end

    it "should update coordinates" do
      request.env["RAW_POST_DATA"] = {coordinates: [76.9,34.2]}.to_json
      put :update_facility, collection_id: collection.id, id: site.id
      expect(response.status).to eq(200)
      json = JSON.parse response.body
      expect(json["name"]).to eq('Kakamega HC')
      expect(json["coordinates"][0]).to eq(76.9)
      expect(json["coordinates"][1]).to eq(34.2)
      updated_site = Site.find site.id
      expect(updated_site.lat.to_f).to eq(34.2)
      expect(updated_site.lng.to_f).to eq(76.9)
    end

    it "should ignore active param in facility creation" do
      request.env["RAW_POST_DATA"] = { active: 'false' }.to_json
      put :update_facility, collection_id: collection.id, id: site.id
      expect(response.status).to eq(200)
      json = JSON.parse response.body
      expect(json["name"]).to eq('Kakamega HC')
      expect(json["active"]).to eq(true)
    end

    it "should update properties" do
      json_data = {
      :manager => "Mrs. Liz 2",
      :numBeds => 552,
      :services => ["OBG"],
      :inagurationDay => "2013-10-24T00:00:00Z"
      }

      request.env["RAW_POST_DATA"] = {properties: json_data}.to_json
      put :update_facility, collection_id: collection.id, id: site.id

      expect(response.status).to eq(200)
      json = JSON.parse response.body
      expect(json["properties"].length).to eq(4)
      expect(json["properties"]['manager']).to eq("Mrs. Liz 2")
      expect(json["properties"]['numBeds']).to eq(552)
      expect(json["properties"]['services']).to eq(['OBG'])
      expect(json["properties"]['inagurationDay']).to eq("2013-10-24T00:00:00Z")
    end

    describe "partial updates" do

      let!(:site_with_properties) { collection.sites.make :properties => {
        text.es_code => "Mrs. Liz",
        numeric.es_code => 55,
        select_many.es_code => [1, 2],
        date.es_code => "2012-10-24T00:00:00Z",
      }}

      it "should update a single property" do
        json_data = {
        :manager => "Mrs. Liz 2"
        }

        request.env["RAW_POST_DATA"] = {properties: json_data}.to_json
        put :update_facility, collection_id: collection.id, id: site_with_properties.id

        response.status.should eq(200)
        json = JSON.parse response.body
        json["name"].should eq(site_with_properties.name)
        json["properties"].length.should eq(4)
        json["properties"]['manager'].should eq("Mrs. Liz 2")
        json["properties"]['numBeds'].should eq(55)
        json["properties"]['services'].should eq(['XR', 'OBG'])
        json["properties"]['inagurationDay'].should eq("2012-10-24T00:00:00Z")
      end

      it "should update multiple properties" do
        json_data = {
        :manager => "Mrs. Liz 2",
        :numBeds => 42
        }

        request.env["RAW_POST_DATA"] = {properties: json_data}.to_json
        put :update_facility, collection_id: collection.id, id: site_with_properties.id

        response.status.should eq(200)
        json = JSON.parse response.body
        json["name"].should eq(site_with_properties.name)
        json["properties"].length.should eq(4)
        json["properties"]['manager'].should eq("Mrs. Liz 2")
        json["properties"]['numBeds'].should eq(42)
        json["properties"]['services'].should eq(['XR', 'OBG'])
        json["properties"]['inagurationDay'].should eq("2012-10-24T00:00:00Z")
      end

      it "should update name and multiple properties" do
        json_data = {
        :manager => "Mrs. Liz 2",
        :numBeds => 42
        }

        request.env["RAW_POST_DATA"] = {properties: json_data, name: 'Mr Abbot Gray'}.to_json
        put :update_facility, collection_id: collection.id, id: site_with_properties.id

        response.status.should eq(200)
        json = JSON.parse response.body
        json["name"].should eq("Mr Abbot Gray")
        json["properties"].length.should eq(4)
        json["properties"]['manager'].should eq("Mrs. Liz 2")
        json["properties"]['numBeds'].should eq(42)
        json["properties"]['services'].should eq(['XR', 'OBG'])
        json["properties"]['inagurationDay'].should eq("2012-10-24T00:00:00Z")
      end
    end

    it "should update identifiers" do
      moh_id = layer.identifier_fields.make :code => 'moh-id', :config => {"context" => "MOH", "agency" => "DHIS"}

      request.env["RAW_POST_DATA"] = {:identifiers => [
        {"agency"=> "DHIS",
        "context"=>"MOH",
        "id"=> "1234"}] }.to_json

      put :update_facility, collection_id: collection.id, id: site.id

      expect(response.status).to eq(200)
      json = JSON.parse response.body
      expect(json['identifiers'][0]).to eq({"context" => "MOH", "agency" => "DHIS", "id"=> "1234"})
    end

    it "should not update uuid" do
      prev_uuid = site.uuid
      request.env["RAW_POST_DATA"] = { :uuid => "c57f5866-f8cb-44b0-8fa5-109aa14ed822" }.to_json
      put :update_facility, collection_id: collection.id, id: site.id
      expect(response.status).to eq(400)
      json = JSON.parse response.body
      expect(json["message"]).to eq("Invalid Paramaters: The id, uuid, url, createdAt and updatedAt core properties cannot be changed by the client.")
      #check that site uuid does not change
      updated_site = Site.find site.id
      expect(updated_site.uuid).to eq(prev_uuid)
    end
  end

  describe "Should create facility" do
    it "should not create a facility without a name" do
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(400)
      json = JSON.parse response.body
      expect(json["message"]).to eq("Validation failed: Name can't be blank")
    end

    it "should create facility with name" do
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC' }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(201)
      site = Site.find_by_name 'Kakamega HC'
      expect(site).to be
      expect(response.location).to start_with("http://test.host/plugin/fred_api/collections/#{collection.id}/fred_api/v1/facilities/#{site.id}.json")
      json = JSON.parse response.body
      expect(json["name"]).to eq(site.name)
      expect(json["uuid"]).to eq("#{site.uuid}")
      expect(json["active"]).to eq(true)
      expect(json["href"]).to start_with("http://test.host/plugin/fred_api/collections/#{collection.id}/fred_api/v1/facilities/#{site.id}.json")
    end

    it "should return 400 if id, url, createdAt or updatedAt are present in the query params" do
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', id: 234 }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(400)

      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', url: "sda" }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(400)

      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', createdAt: "sda" }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(400)

      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', updatedAt: "sda" }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(400)
    end

    # Resourcemap does not consider sites with the same name as duplicated
    skip "should return 409 for facilities with duplicated names" do
      site = collection.sites.create :name => "Duplicated name"
      request.env["RAW_POST_DATA"] = { name: "Duplicated name" }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(409)
    end

    it "should create facility with coordinates" do
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', coordinates: [76.9,34.2] }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(201)
      json = JSON.parse response.body
      expect(json["name"]).to eq('Kakamega HC')
      expect(json["coordinates"][0]).to eq(76.9)
      expect(json["coordinates"][1]).to eq(34.2)
    end

    it "should ignore active param in facility creation" do
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', active: 'false' }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(201)
      json = JSON.parse response.body
      expect(json["name"]).to eq('Kakamega HC')
      expect(json["active"]).to eq(true)
    end

    it "should create facility with coordinates" do
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', coordinates: [76.9,34.2] }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(201)
      json = JSON.parse response.body
      expect(json["name"]).to eq('Kakamega HC')
      expect(json["coordinates"][0]).to eq(76.9)
      expect(json["coordinates"][1]).to eq(34.2)
    end

    it "should create a facility with properties" do
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', :properties => {
        "manager" => "Mrs. Liz",
        "numBeds" => 55,
        "services" => ['XR', 'OBG'],
        "inagurationDay" => "2012-10-24T00:00:00Z"
      } }.to_json
      post :create_facility, collection_id: collection.id

      expect(response.status).to eq(201)
      json = JSON.parse response.body
      expect(json["properties"].length).to eq(4)
      expect(json["properties"]['manager']).to eq("Mrs. Liz")
      expect(json["properties"]['numBeds']).to eq(55)
      expect(json["properties"]['services']).to eq(['XR', 'OBG'])
      expect(json["properties"]['inagurationDay']).to eq("2012-10-24T00:00:00Z")
    end

    it "should return descriptive error if an invalid property code is supplied" do
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', :properties => {
        "invalid" => "Mrs. Liz",
      } }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(400)
      json = JSON.parse response.body
      expect(json["message"]).to eq("Invalid Parameters: Cannot find Field with code equal to 'invalid' in Collection's Layers.")
    end

    it "should create a facility with identifiers" do
      moh_id = layer.identifier_fields.make :code => 'moh-id', :config => {"context" => "MOH", "agency" => "DHIS"}
      moh_id2 = layer.identifier_fields.make :code => 'moh-id2', :config => {"context" => "MOH2", "agency" => "DHIS2"}

      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', :identifiers => [
        {"agency"=> "DHIS",
        "context"=>"MOH",
        "id"=> "123"},
        {"agency"=> "DHIS2",
        "context"=> "MOH2",
        "id"=>"124"}] }.to_json
      post :create_facility, collection_id: collection.id

      expect(response.status).to eq(201)
      json = JSON.parse response.body
      expect(json['identifiers'][0]).to eq({"context" => "MOH", "agency" => "DHIS", "id"=> "123"})
      expect(json['identifiers'][1]).to eq({"context" => "MOH2", "agency" => "DHIS2", "id"=> "124"})
    end

    it "should return descriptive error if an invalid identifier field supplied" do
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', :identifiers => [
        {"agency"=> "DHIS",
        "context"=>"MOH",
        "id"=> "123"}
      ] }.to_json

      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(400)
      json = JSON.parse response.body
      expect(json["message"]).to eq("Invalid Parameters: Cannot find Identifier Field with context equal to 'MOH' and agency equal to 'DHIS' in Collection's Layers.")
    end

    it "should create a facility with uuid" do
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', :uuid => "c57f5866-f8cb-44b0-8fa5-109aa14ed822" }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(201)
      json = JSON.parse response.body
      expect(json['uuid']).to eq("c57f5866-f8cb-44b0-8fa5-109aa14ed822")
    end

    it "should not create facility with invalid uuid" do
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', :uuid => "1245" }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(400)
      json = JSON.parse response.body
      expect(json["message"]).to eq("Validation failed: Uuid is not valid")
      expect(Site.find_by_name 'Kakamega HC').to be_nil
    end

    it "should return 409 if facility uuid is duplicated in the collection" do
      site = collection.sites.make
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', :uuid => site.uuid }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(409)
      json = JSON.parse response.body
      expect(json["message"]).to eq("Duplicated facility: UUID has already been taken in this collection.")
    end

  end

  describe "External Facility Identifiers" do
    let(:moh_id) {layer.identifier_fields.make :code => 'moh-id', :config => {"context" => "MOH", "agency" => "DHIS"} }

     let!(:site_with_metadata) { collection.sites.make :properties => {
        moh_id.es_code => "53adf",
        date.es_code => "2012-10-24T00:00:00Z",
      }}

    it "should return identifiers in single facility query" do
      get :show_facility, id: site_with_metadata.id, format: 'json', collection_id: collection.id
      json = JSON.parse response.body

      expect(json["name"]).to eq(site_with_metadata.name)
      expect(json["uuid"]).to eq("#{site_with_metadata.uuid}")
      expect(json["identifiers"].length).to eq(1)
      expect(json["identifiers"][0]).to eq({"context" => "MOH", "agency" => "DHIS", "id"=> "53adf"})
    end

    it 'should filter by identifier', focus: true do
      get :facilities, format: 'json',  collection_id: collection.id, "identifiers.id" => "53adf"
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(1)
      expect(json[0]['uuid']).to eq("#{site_with_metadata.uuid}")
    end

    it 'should filter by identifier and agency' do
      get :facilities, format: 'json',  collection_id: collection.id, "identifiers.agency" => "DHIS", "identifiers.id" => "53adf"
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(1)
      expect(json[0]['uuid']).to eq("#{site_with_metadata.uuid}")
    end

    it 'should filter by identifier and context' do
      get :facilities, format: 'json',  collection_id: collection.id, "identifiers.context" => "MOH", "identifiers.id" => "53adf"
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(1)
      expect(json[0]['uuid']).to eq("#{site_with_metadata.uuid}")
    end

    it 'should filter by identifier, context and agency' do
      get :facilities, format: 'json',  collection_id: collection.id, "identifiers.context" => "MOH", "identifiers.id" => "53adf", "identifiers.agency" => "DHIS"
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(1)
      expect(json[0]['uuid']).to eq("#{site_with_metadata.uuid}")
    end

    it 'sholud return an empty list if the id does not match' do get :facilities, format: 'json',  collection_id: collection.id, "identifiers.context" => "MOH", "identifiers.id" => "invalid", "identifiers.agency" => "DHIS"
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(0)
    end

    it 'sholud return an empty list if the context does not match any identifier' do
      get :facilities, format: 'json',  collection_id: collection.id, "identifiers.context" => "invalid", "identifiers.id" => "53adf", "identifiers.agency" => "DHIS"
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(0)
    end

    it 'sholud return an empty list if the agency does not match any identifier' do
      get :facilities, format: 'json',  collection_id: collection.id, "identifiers.context" => "MOH", "identifiers.id" => "53adf", "identifiers.agency" => "invalid"
      json = (JSON.parse response.body)["facilities"]
      expect(json.length).to eq(0)
    end

  end

  describe "Luhn identifiers" do
    let!(:luhn_id) {layer.identifier_fields.make :code => 'moh-id', :config => {"context" => "MOH", "agency" => "DHIS", "format" => "Luhn"} }

    it 'should create facility with a default value for the identifier field' do
      request.env["RAW_POST_DATA"] = { name: 'Kakamega HC' }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(201)
      site = Site.find_by_name 'Kakamega HC'
      expect(site).to be
      expect(site.valid?).to be(true)

      expect(response.location).to start_with("http://test.host/plugin/fred_api/collections/#{collection.id}/fred_api/v1/facilities/#{site.id}.json")
      json = JSON.parse response.body
      expect(json["properties"]['moh-id']).to eq("100000-9")
      expect(json["name"]).to eq(site.name)
      expect(json["uuid"]).to eq("#{site.uuid}")
      expect(json["active"]).to eq(true)
      expect(json["href"]).to start_with("http://test.host/plugin/fred_api/collections/#{collection.id}/fred_api/v1/facilities/#{site.id}.json")
    end

    it 'should create facility with with the next valid luhn identifier if there is a site with luhn value' do
      site = collection.sites.make
      site.assign_default_values_for_create
      site.save!

      request.env["RAW_POST_DATA"] = { name: 'Kizikuo' }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(201)
      site = Site.find_by_name 'Kizikuo'
      expect(site.valid?).to be(true)

      json = JSON.parse response.body
      expect(json["properties"]['moh-id']).to eq("100001-7")
    end

    it 'should create facility with with a valid luhn identifier if there is a site without luhn value' do
      site = collection.sites.make
      site.save!

      # we are not calling assign_default_values_for_create so this site will not have a value for the luhn_id field
      # this situation can happen if this site is created using the UI, deleting the suggested luhn value.
      expect(site.properties["#{luhn_id.es_code}"]).to be(nil)

      request.env["RAW_POST_DATA"] = { name: 'Kizikuo' }.to_json
      post :create_facility, collection_id: collection.id
      expect(response.status).to eq(201)

      site = Site.find_by_name 'Kizikuo'
      expect(site.valid?).to be(true)

      json = JSON.parse response.body
      expect(json["properties"]['moh-id']).to eq("100000-9")
    end

  end

end
