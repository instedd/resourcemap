require 'spec_helper'

describe FredApi::FredApiController do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:layer) { collection.layers.make }

  # We test only the field types supported by FRED API
  let!(:text) { layer.fields.make :code => 'manager', :kind => 'text' }
  let!(:numeric) { layer.fields.make :code => 'numBeds', :kind => 'numeric' }
  let!(:select_many) { layer.fields.make :code => 'services', :kind => 'select_many', :config => {'options' => [{'id' => 1, 'code' => 'XR', 'label' => 'X-ray'}, {'id' => 2, 'code' => 'OBG', 'label' => 'Gynecology'}]} }
  let!(:date) { layer.fields.make :code => 'inagurationDay', :kind => 'date' }

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
      get :show_facility, id: site.id, format: 'json'
      response.should be_success
      response.content_type.should eq 'application/json'

      json = JSON.parse response.body
      json["name"].should eq(site.name)
      json["id"].should eq(site.id)
      json["coordinates"][0].should eq(site.lng)
      json["coordinates"][1].should eq(site.lat)
      json["active"].should eq(true)
      json["url"].should eq("http://test.host/fred_api/v1/facilities/#{site.id}.json")

    end

    it 'should get extended properties' do
      get :show_facility, id: site_with_properties.id, format: 'json'

      json = JSON.parse response.body
      json["properties"].length.should eq(4)
      json["properties"]['manager'].should eq("Mrs. Liz")
      json["properties"]['numBeds'].should eq(55)
      json["properties"]['services'].should eq(['XR', 'OBG'])
      json["properties"]['inagurationDay'].should eq("2012-10-24T00:00:00Z")
    end
  end

  describe "query list of facilities" do
    let!(:site1) { collection.sites.make name: 'Site A', properties:{ date.es_code => "2012-10-24T00:00:00Z"} }
    let!(:site2) { collection.sites.make name: 'Site B', properties:{ date.es_code => "2012-10-25T00:00:00Z"} }

    it 'should get the full list of facilities' do
      get :facilities, format: 'json'
      response.should be_success
      response.content_type.should eq 'application/json'

      json = JSON.parse response.body
      json.length.should eq(2)
    end

    it 'should sort the list of facilities by name asc' do
      get :facilities, format: 'json', sortAsc: 'name'

      json = JSON.parse response.body
      json.length.should eq(2)
      json[0]["name"].should eq(site1.name)
      json[1]["name"].should eq(site2.name)
    end

    it 'should sort the list of facilities by name desc' do
      get :facilities, format: 'json', sortDesc: 'name'

      json = JSON.parse response.body
      json.length.should eq(2)
      json[0]["name"].should eq(site2.name)
      json[1]["name"].should eq(site1.name)
    end

    it 'should sort the list of facilities by property date' do
      get :facilities, format: 'json', sortDesc: 'inagurationDay'

      json = JSON.parse response.body
      json.length.should eq(2)
      json[0]["name"].should eq(site2.name)
      json[1]["name"].should eq(site1.name)
    end

    it 'should limit the number of facilities returned and the offset for the query' do
      get :facilities, format: 'json', limit: 1
      json = JSON.parse response.body
      json.length.should eq(1)
      json[0]["name"].should eq(site1.name)
      get :facilities, format: 'json', limit: 1, offset: 1
      json = JSON.parse response.body
      json.length.should eq(1)
      json[0]["name"].should eq(site2.name)
    end

    it 'should select only default fields' do
      get :facilities, format: 'json', fields: "name,id"
      json = JSON.parse response.body
      json.length.should eq(2)
      json[0].length.should eq(2)
      json[0]['name'].should eq(site1.name)
      json[0]['id'].should eq(site1.id)

      json[1].length.should eq(2)
      json[1]['name'].should eq(site2.name)
      json[1]['id'].should eq(site2.id)
    end

    it 'should select default and custom fields' do
      get :facilities, format: 'json', fields: "name,properties:inagurationDay"
      json = JSON.parse response.body
      json.length.should eq(2)
      json[0].length.should eq(2)
      json[0]['name'].should eq(site1.name)
      json[0]['properties']['inagurationDay'].should eq("2012-10-24T00:00:00Z")

      json[1].length.should eq(2)
      json[1]['name'].should eq(site2.name)
      json[1]['properties']['inagurationDay'].should eq("2012-10-25T00:00:00Z")
    end

   it 'should return all fields (default and custom) when parameter allProperties is set' do
      get :facilities, format: 'json', allProperties: true
      json = JSON.parse response.body
      json.length.should eq(2)
      json[0].length.should eq(8)
      json[0]['properties'].length.should eq(1)

      json[1].length.should eq(8)
      json[1]['properties'].length.should eq(1)
    end

    describe "Filtering Facilities" do

      it "should filter by name" do
        get :facilities, format: 'json', name: site1.name
        json = JSON.parse response.body
        json.length.should eq(1)
        json[0]['name'].should eq(site1.name)
      end

      it "should filter by id" do
        get :facilities, format: 'json', id: site1.id
        json = JSON.parse response.body
        json.length.should eq(1)
        json[0]['id'].should eq(site1.id)
      end

      it "should filter by coordinates" do
        get :facilities, format: 'json', coordinates: [site1.lng.to_f, site1.lat.to_f]
        json = JSON.parse response.body
        json.length.should eq(1)
        json[0]['id'].should eq(site1.id)
      end

      it "should filter by updated_at" do
        #this query has a 2 seconds bound
        sleep 3
        site3 = collection.sites.make name: 'Site C'
        iso_updated_at = Time.zone.parse(site3.updated_at.to_s).utc.iso8601
        get :facilities, format: 'json', updatedAt: iso_updated_at
        json = JSON.parse response.body
        json.length.should eq(1)
        json[0]['id'].should eq(site3.id)
      end

      it "should filter by created_at" do
        #this query has a 2 seconds bound
        sleep 3
        site3 = collection.sites.make name: 'Site C'
        iso_created_at = Time.zone.parse(site3.created_at.to_s).utc.iso8601
        get :facilities, format: 'json', createdAt: iso_created_at
        json = JSON.parse response.body
        json.length.should eq(1)
        json[0]['id'].should eq(site3.id)
      end

      it "should filter by active" do
        #All ResourceMap facilities are active, because ResourceMap does not implement logical deletion yet
        get :facilities, format: 'json', active: false
        json = JSON.parse response.body
        json.length.should eq(0)
      end

      it "should filter by updated since" do
        sleep 3
        iso_before_update = Time.zone.now.utc.iso8601
        site1.name = "Site A New"
        site1.save!
        get :facilities, format: 'json', updatedSince: iso_before_update
        json = JSON.parse response.body
        json.length.should eq(1)
        json[0]['id'].should eq(site1.id)
      end

    end

  end

  describe "delete facility" do
    it "should delete facility" do
      site3 = collection.sites.make name: 'Site C'
      delete :delete_facility, id: site3.id
      sites = Site.find_by_name 'Site C'
      sites.should be(nil)
    end
  end


end