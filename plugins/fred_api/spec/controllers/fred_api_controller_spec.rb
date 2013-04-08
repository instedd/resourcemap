  require 'spec_helper'

  describe FredApiController do
    include Devise::TestHelpers

    let!(:user) { User.make }
    let!(:collection) { user.create_collection(Collection.make) }
    let!(:layer) { collection.layers.make }

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
        response.should be_ok
        response.content_type.should eq 'application/json'

        json = JSON.parse response.body
        json["name"].should eq(site.name)
        json["id"].should eq("#{site.id}")
        json["coordinates"][0].should eq(site.lng)
        json["coordinates"][1].should eq(site.lat)
        json["active"].should eq(true)
        json["url"].should eq("http://test.host/plugin/fred_api/collections/#{collection.id}/fred_api/v1/facilities/#{site.id}.json")

      end

      it 'should get extended properties' do
        get :show_facility, id: site_with_properties.id, format: 'json', collection_id: collection.id

        json = JSON.parse response.body
        json["properties"].length.should eq(4)
        json["properties"]['manager'].should eq("Mrs. Liz")
        json["properties"]['numBeds'].should eq(55)
        json["properties"]['services'].should eq(['XR', 'OBG'])
        json["properties"]['inagurationDay'].should eq("2012-10-24T00:00:00Z")
      end

      it "should convert time in different timezone to UTC" do
        stub_time Time.iso8601("2013-02-04T20:25:27-03:00").to_s
        site2 = collection.sites.make name: 'Arg Site'
        get :show_facility, id: site2.id, format: 'json', collection_id: collection.id
        json = JSON.parse response.body
        json["createdAt"].should eq("2013-02-04T23:25:27Z")
      end
    end

    describe "query list of facilities" do
      let!(:site1) { collection.sites.make name: 'Site A', properties:{ date.es_code => "2012-10-24T00:00:00Z"} }
      let!(:site2) { collection.sites.make name: 'Site B', properties:{ date.es_code => "2012-10-25T00:00:00Z"} }

      it 'should get the full list of facilities' do
        get :facilities, format: 'json', collection_id: collection.id
        response.should be_success
        response.content_type.should eq 'application/json'

        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(2)
      end

      it 'should sort the list of facilities by name asc' do
        get :facilities, format: 'json', sortAsc: 'name', collection_id: collection.id

        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(2)
        json[0]["name"].should eq(site1.name)
        json[1]["name"].should eq(site2.name)
      end

      it 'should sort the list of facilities by name desc' do
        get :facilities, format: 'json', sortDesc: 'name', collection_id: collection.id

        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(2)
        json[0]["name"].should eq(site2.name)
        json[1]["name"].should eq(site1.name)
      end

      it 'should sort the list of facilities by property date' do
        get :facilities, format: 'json', sortDesc: 'inagurationDay', collection_id: collection.id

        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(2)
        json[0]["name"].should eq(site2.name)
        json[1]["name"].should eq(site1.name)
      end

      describe 'limit' do
        (3..100).each do |i|
          let!("site#{i}".to_sym) { collection.sites.make name: "Site C#{i}", properties:{ date.es_code => "2012-10-26T00:00:00Z"} }
        end

        it 'should limit the number of facilities returned and the offset for the query' do
          get :facilities, format: 'json', limit: 1, collection_id: collection.id
          json = (JSON.parse response.body)["facilities"]
          json.length.should eq(1)
          json[0]["name"].should eq(site1.name)
          get :facilities, format: 'json', limit: 1, offset: 1, collection_id: collection.id
          json = (JSON.parse response.body)["facilities"]
          json.length.should eq(1)
          json[0]["name"].should eq(site2.name)
        end

        it 'should not limit the number of facilities when limit=off' do


          get :facilities, format: 'json', limit: "off", collection_id: collection.id
          json = (JSON.parse response.body)["facilities"]

          # 98 sites created inside this test case, and 2 under "query list of facilities" describe scope
          json.length.should eq(100)
        end
      end

      it 'should select only default fields' do
        get :facilities, format: 'json', fields: "name,id", collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(2)
        json[0].length.should eq(2)
        json[0]['name'].should eq(site1.name)
        json[0]['id'].should eq(site1.id.to_s)

        json[1].length.should eq(2)
        json[1]['name'].should eq(site2.name)
        json[1]['id'].should eq(site2.id.to_s)
      end

      it 'should select default and custom fields' do
        get :facilities, format: 'json', fields: "name,properties:inagurationDay", collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(2)
        json[0].length.should eq(2)
        json[0]['name'].should eq(site1.name)
        json[0]['properties']['inagurationDay'].should eq("2012-10-24T00:00:00Z")

        json[1].length.should eq(2)
        json[1]['name'].should eq(site2.name)
        json[1]['properties']['inagurationDay'].should eq("2012-10-25T00:00:00Z")
      end

     it 'should return all fields (default and custom) when parameter allProperties is set' do
        get :facilities, format: 'json', allProperties: true, collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(2)
        json[0]['properties'].length.should eq(1)
        json[1]['properties'].length.should eq(1)
      end
    end

    describe "Filtering Facilities" do
      let!(:site1) { collection.sites.make name: 'Site A', properties:{ numeric.es_code => 55} }
      let!(:site2) { collection.sites.make name: 'Site B', properties:{ numeric.es_code => 56} }


      it "should filter by name" do
        get :facilities, format: 'json', name: site1.name, collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(1)
        json[0]['name'].should eq(site1.name)
      end

      it "should filter by id" do
        get :facilities, format: 'json', id: site1.id, collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(1)
        json[0]['id'].should eq(site1.id.to_s)
      end

      it "should filter by coordinates" do
        get :facilities, format: 'json', coordinates: [site1.lng.to_f, site1.lat.to_f], collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(1)
        json[0]['id'].should eq(site1.id.to_s)
      end

      it "should filter by updated_at" do
        #this query has a 2 seconds bound
        sleep 3
        site3 = collection.sites.make name: 'Site C'
        iso_updated_at = Time.zone.parse(site3.updated_at.to_s).utc.iso8601
        get :facilities, format: 'json', updatedAt: iso_updated_at, collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(1)
        json[0]['id'].should eq(site3.id.to_s)
      end

      it "should filter by created_at" do
        #this query has a 2 seconds bound
        sleep 3
        site3 = collection.sites.make name: 'Site C'
        iso_created_at = Time.zone.parse(site3.created_at.to_s).utc.iso8601
        get :facilities, format: 'json', createdAt: iso_created_at, collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(1)
        json[0]['id'].should eq(site3.id.to_s)
      end

      it "should filter by active" do
        #All ResourceMap facilities are active, because ResourceMap does not implement logical deletion yet
        get :facilities, format: 'json', active: 'false', collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(0)
      end

      it "should filter by updated since" do
        sleep 3
        iso_before_update = Time.zone.now.utc.iso8601
        site1.name = "Site A New"
        site1.save!
        get :facilities, format: 'json', updatedSince: iso_before_update, collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(1)
        json[0]['id'].should eq(site1.id.to_s)
      end

      it "should filter by updated since with miliseconds" do
        sleep 3
        iso_before_update = Time.zone.now.utc.iso8601 5
        site1.name = "Site A New"
        site1.save!
        get :facilities, format: 'json', updatedSince: iso_before_update, collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(1)
        json[0]['id'].should eq(site1.id.to_s)
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
        json.length.should eq(2)
        json[0]['id'].should eq(site4.id.to_s)
        json[1]['id'].should eq(site5.id.to_s)
      end

      it "should filter by property with 'properties.' prefix" do
        get :facilities, format: 'json', "properties.numBeds" => 55, collection_id: collection.id
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(1)
        json[0]['name'].should eq(site1.name)
      end

    end

    describe "delete facility" do
      it "should delete facility" do
        site3 = collection.sites.make name: 'Site C'
        delete :delete_facility, id: site3.id, collection_id: collection.id
        response.body.should eq("http://test.host/plugin/fred_api/collections/#{collection.id}/fred_api/v1/facilities/#{site3.id}.json")
        sites = Site.find_by_name 'Site C'
        sites.should be(nil)
      end
    end

    describe "http status codes" do
      let!(:site) { collection.sites.make }
      it "should return 200 in a valid request" do
        get :show_facility, id: site.id, format: 'json', collection_id: collection.id
        response.should be_success
      end

      it "should return 401 if the user is not signed_in" do
        sign_out user
        get :show_facility, id: site.id, format: 'json', collection_id: collection.id
        response.status.should eq(401)
      end

      it "should return 401 if the user is not signed_in" do
        sign_out user
        get :show_facility, id: site.id, format: 'json', collection_id: collection.id
        response.status.should eq(401)
      end

      it "should return 403 if user is do not have permission to access the site" do
        user2 = User.make
        sign_out user
        sign_in user2
        get :show_facility, id: site.id, format: 'json', collection_id: collection.id
        response.status.should eq(403)
      end

      it "should return 403 if user is do not have permission to access the collection" do
        collection2 = Collection.make
        get :show_facility, id: site.id, format: 'json', collection_id: collection2.id
        response.status.should eq(403)
      end

      it "should return 409 if the site do not belong to the collection" do
        collection2 = Collection.make
        user.create_collection(collection2)
        get :show_facility, id: site.id, format: 'json', collection_id: collection2.id
        response.status.should eq(409)
      end

      it "should return 404 if the requested site does not exist" do
        get :show_facility, id: 12355259, format: 'json', collection_id: collection.id
        response.status.should eq(404)
        json = JSON.parse response.body
        json['code'].should eq('404 Not Found')
        json['message'].should eq('Resource not found')
      end

      it "should return 422 if a non existing field is included in the query" do
        get :facilities, format: 'json', invalid: "option", collection_id: collection.id
        response.status.should eq(422)
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
        response.status.should eq(404)
      end

      it "should update name" do
        request.env["RAW_POST_DATA"] = { :name => "Kakamega HC 2" }.to_json
        put :update_facility, collection_id: collection.id, id: site.id
        response.status.should eq(200)
        updated_site = Site.find site.id
        updated_site.name.should eq("Kakamega HC 2")
      end

     it "should return 400 if id, url, createdAt or updatedAt are present in the query params" do
       request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', url: "sda" }.to_json
        put :update_facility, collection_id: collection.id, id: site.id
        response.status.should eq(400)

        request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', createdAt: "sda" }.to_json
        put :update_facility, collection_id: collection.id, id: site.id
        response.status.should eq(400)

        request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', updatedAt: "sda" }.to_json
        put :update_facility, collection_id: collection.id, id: site.id
        response.status.should eq(400)
      end

      it "should update  coordinates" do
        request.env["RAW_POST_DATA"] = {coordinates: [76.9,34.2]}.to_json
        put :update_facility, collection_id: collection.id, id: site.id
        response.status.should eq(200)
        json = JSON.parse response.body
        json["name"].should eq('Kakamega HC')
        json["coordinates"][0].should eq(76.9)
        json["coordinates"][1].should eq(34.2)
        updated_site = Site.find site.id
        updated_site.lat.to_f.should eq(34.2)
        updated_site.lng.to_f.should eq(76.9)
      end

      it "should ignore active param in facility creation" do
        request.env["RAW_POST_DATA"] = { active: 'false' }.to_json
        put :update_facility, collection_id: collection.id, id: site.id
        response.status.should eq(200)
        json = JSON.parse response.body
        json["name"].should eq('Kakamega HC')
        json["active"].should eq(true)
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

        response.status.should eq(200)
        json = JSON.parse response.body
        json["properties"].length.should eq(4)
        json["properties"]['manager'].should eq("Mrs. Liz 2")
        json["properties"]['numBeds'].should eq(552)
        json["properties"]['services'].should eq(['OBG'])
        json["properties"]['inagurationDay'].should eq("2013-10-24T00:00:00Z")
      end

      it "should update identifiers" do
        moh_id = layer.identifier_fields.make :code => 'moh-id', :config => {"context" => "MOH", "agency" => "DHIS"}

        request.env["RAW_POST_DATA"] = {:identifiers => [
          {"agency"=> "DHIS",
          "context"=>"MOH",
          "id"=> "1234"}] }.to_json

        put :update_facility, collection_id: collection.id, id: site.id

        response.status.should eq(200)
        json = JSON.parse response.body
        json['identifiers'][0].should eq({"context" => "MOH", "agency" => "DHIS", "id"=> "1234"})
      end
    end

    describe "Should create facility" do
      it "should not create a facility without a name" do
        post :create_facility, collection_id: collection.id
        response.status.should eq(422)
      end

      it "should create facility with name" do
        request.env["RAW_POST_DATA"] = { name: 'Kakamega HC' }.to_json
        post :create_facility, collection_id: collection.id
        response.status.should eq(201)
        site = Site.find_by_name 'Kakamega HC'
        site.should be
        response.location.should eq("http://test.host/plugin/fred_api/collections/#{collection.id}/fred_api/v1/facilities/#{site.id}.json")
        json = JSON.parse response.body
        json["name"].should eq(site.name)
        json["id"].should eq("#{site.id}")
        json["active"].should eq(true)
        json["url"].should eq("http://test.host/plugin/fred_api/collections/#{collection.id}/fred_api/v1/facilities/#{site.id}.json")
      end

      it "should return 400 if id, url, createdAt or updatedAt are present in the query params" do
        request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', id: 234 }.to_json
        post :create_facility, collection_id: collection.id
        response.status.should eq(400)

        request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', url: "sda" }.to_json
        post :create_facility, collection_id: collection.id
        response.status.should eq(400)

        request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', createdAt: "sda" }.to_json
        post :create_facility, collection_id: collection.id
        response.status.should eq(400)

        request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', updatedAt: "sda" }.to_json
        post :create_facility, collection_id: collection.id
        response.status.should eq(400)
      end

      # Resourcemap does not consider sites with the same name as duplicated
      pending "should return 409 for facilities with duplicated names" do
        site = collection.sites.create :name => "Duplicated name"
        request.env["RAW_POST_DATA"] = { name: "Duplicated name" }.to_json
        post :create_facility, collection_id: collection.id
        response.status.should eq(409)
      end

      it "should create facility with coordinates" do
        request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', coordinates: [76.9,34.2] }.to_json
        post :create_facility, collection_id: collection.id
        response.status.should eq(201)
        json = JSON.parse response.body
        json["name"].should eq('Kakamega HC')
        json["coordinates"][0].should eq(76.9)
        json["coordinates"][1].should eq(34.2)
      end

      it "should ignore active param in facility creation" do
        request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', active: 'false' }.to_json
        post :create_facility, collection_id: collection.id
        response.status.should eq(201)
        json = JSON.parse response.body
        json["name"].should eq('Kakamega HC')
        json["active"].should eq(true)
      end

      it "should create facility with coordinates" do
        request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', coordinates: [76.9,34.2] }.to_json
        post :create_facility, collection_id: collection.id
        response.status.should eq(201)
        json = JSON.parse response.body
        json["name"].should eq('Kakamega HC')
        json["coordinates"][0].should eq(76.9)
        json["coordinates"][1].should eq(34.2)
      end

      it "should create a facility with properties" do
        request.env["RAW_POST_DATA"] = { name: 'Kakamega HC', :properties => {
          "manager" => "Mrs. Liz",
          "numBeds" => 55,
          "services" => ['XR', 'OBG'],
          "inagurationDay" => "2012-10-24T00:00:00Z"
        } }.to_json
        post :create_facility, collection_id: collection.id

        response.status.should eq(201)
        json = JSON.parse response.body
        json["properties"].length.should eq(4)
        json["properties"]['manager'].should eq("Mrs. Liz")
        json["properties"]['numBeds'].should eq(55)
        json["properties"]['services'].should eq(['XR', 'OBG'])
        json["properties"]['inagurationDay'].should eq("2012-10-24T00:00:00Z")

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

        response.status.should eq(201)
        json = JSON.parse response.body
        json['identifiers'][0].should eq({"context" => "MOH", "agency" => "DHIS", "id"=> "123"})
        json['identifiers'][1].should eq({"context" => "MOH2", "agency" => "DHIS2", "id"=> "124"})
      end
    end

    describe "External Facility Identifiers" do
      let!(:moh_id) {layer.identifier_fields.make :code => 'moh-id', :config => {"context" => "MOH", "agency" => "DHIS"} }

       let!(:site_with_metadata) { collection.sites.make :properties => {
          moh_id.es_code => "53adf",
          date.es_code => "2012-10-24T00:00:00Z",
        }}

      it "should return identifiers in single facility query" do
        get :show_facility, id: site_with_metadata.id, format: 'json', collection_id: collection.id
        json = JSON.parse response.body

        json["name"].should eq(site_with_metadata.name)
        json["id"].should eq("#{site_with_metadata.id}")
        json["identifiers"].length.should eq(1)
        json["identifiers"][0].should eq({"context" => "MOH", "agency" => "DHIS", "id"=> "53adf"})
      end

      it 'should filter by identifier', focus: true do
        get :facilities, format: 'json',  collection_id: collection.id, "identifiers.id" => "53adf"
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(1)
        json[0]['id'].should eq("#{site_with_metadata.id}")
      end

      it 'should filter by identifier and agency' do
        get :facilities, format: 'json',  collection_id: collection.id, "identifiers.agency" => "DHIS", "identifiers.id" => "53adf"
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(1)
        json[0]['id'].should eq("#{site_with_metadata.id}")
      end

      it 'should filter by identifier and context' do
        get :facilities, format: 'json',  collection_id: collection.id, "identifiers.context" => "MOH", "identifiers.id" => "53adf"
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(1)
        json[0]['id'].should eq("#{site_with_metadata.id}")
      end

      it 'should filter by identifier, context and agency' do
        get :facilities, format: 'json',  collection_id: collection.id, "identifiers.context" => "MOH", "identifiers.id" => "53adf", "identifiers.agency" => "DHIS"
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(1)
        json[0]['id'].should eq("#{site_with_metadata.id}")
      end

      it 'sholud return an empty list if the id does not match' do get :facilities, format: 'json',  collection_id: collection.id, "identifiers.context" => "MOH", "identifiers.id" => "invalid", "identifiers.agency" => "DHIS"
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(0)
      end

      it 'sholud return an empty list if the context does not match any identifier' do get :facilities, format: 'json',  collection_id: collection.id, "identifiers.context" => "invalid", "identifiers.id" => "53adf", "identifiers.agency" => "DHIS"
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(0)
      end

      it 'sholud return an empty list if the agency does not match any identifier' do get :facilities, format: 'json',  collection_id: collection.id, "identifiers.context" => "MOH", "identifiers.id" => "53adf", "identifiers.agency" => "invalid"
        json = (JSON.parse response.body)["facilities"]
        json.length.should eq(0)
      end

    end

  end
