require 'spec_helper'

describe FredApi::FredApiController do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:layer) { collection.layers.make }

  before(:each) { sign_in user }

  describe "GET facility" do

    let!(:site) { collection.sites.make }

    # We test only the field types supported by FRED API
    let!(:text) { layer.fields.make :code => 'manager', :kind => 'text' }
    let!(:numeric) { layer.fields.make :code => 'numBeds', :kind => 'numeric' }
    let!(:select_many) { layer.fields.make :code => 'services', :kind => 'select_many', :config => {'options' => [{'id' => 1, 'code' => 'XR', 'label' => 'X-ray'}, {'id' => 2, 'code' => 'OBG', 'label' => 'Gynecology'}]} }
    let!(:date) { layer.fields.make :code => 'inagurationDay', :kind => 'date' }

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

  describe "GET list of facilities" do
    let!(:site) { collection.sites.make }
    let!(:site2) { collection.sites.make }

    it 'should get the full list of facilities' do
      get :facilities, format: 'json'
      response.should be_success
      response.content_type.should eq 'application/json'

      json = JSON.parse response.body
      json.length.should eq(2)
    end

  end

end