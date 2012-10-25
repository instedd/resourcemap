require 'spec_helper'

describe Api::CollectionsController do
  include Devise::TestHelpers
  render_views

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:layer) { collection.layers.make }

  let!(:text) { layer.fields.make :code => 'text', :kind => 'text' }
  let!(:numeric) { layer.fields.make :code => 'numeric', :kind => 'numeric' }
  let!(:select_one) { layer.fields.make :code => 'select_one', :kind => 'select_one', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  let!(:select_many) { layer.fields.make :code => 'select_many', :kind => 'select_many', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  let!(:hierarchy) { layer.fields.make :code => 'hierarchy', :kind => 'hierarchy',  config: {hierarchy: [{"0"=>{"id"=>"dad", "name"=>"Dad"}, sub: [{"0"=> {"id"=>"son", "name"=>"Son"}, "1"=>{"id"=>"bro", "name"=>"Bro"}}.with_indifferent_access]}]}.with_indifferent_access}
  let!(:site_ref) { layer.fields.make :code => 'site', :kind => 'site' }
  let!(:date) { layer.fields.make :code => 'date', :kind => 'date' }
  let!(:director) { layer.fields.make :code => 'user', :kind => 'user' }

  let!(:site2) {collection.sites.make}

  let!(:site) { collection.sites.make :properties => {
    text.es_code => 'foo',
    numeric.es_code => 1,
    select_one.es_code => 1,
    select_many.es_code => [1, 2],
    hierarchy.es_code => 'dad',
    site_ref.es_code => site2.id,
    date.es_code => "2012-10-24T03:00:00.000Z",
    director.es_code => user.email }
  }

  before(:each) { sign_in user }

  describe "GET JSON collection" do
    before(:each) do
      get :show, id: collection.id, format: 'json'
    end

    it { response.should be_success }

    it "should return JSON" do
      json = JSON.parse response.body
      json["name"].should eq(collection.name)
      json["sites"].length.should eq(2)

      json["sites"][0]["id"].should eq(site2.id)
      json["sites"][0]["name"].should eq(site2.name)
      json["sites"][0]["lat"].should eq(site2.lat)
      json["sites"][0]["long"].should eq(site2.lng)

      json["sites"][0]["properties"].length.should eq(0)

      json["sites"][1]["id"].should eq(site.id)
      json["sites"][1]["name"].should eq(site.name)
      json["sites"][1]["lat"].should eq(site.lat)
      json["sites"][1]["long"].should eq(site.lng)

      json["sites"][1]["properties"].length.should eq(8)

      json["sites"][1]["properties"][text.code].should eq(site.properties[text.es_code])
      json["sites"][1]["properties"][numeric.code].should eq(site.properties[numeric.es_code])
      json["sites"][1]["properties"][select_one.code].should eq('one')
      json["sites"][1]["properties"][select_many.code].should eq(['one', 'two'])
      json["sites"][1]["properties"][hierarchy.code].should eq("dad")
      json["sites"][1]["properties"][site_ref.code].should eq(site2.id)
      json["sites"][1]["properties"][date.code].should eq('10/24/2012')
      json["sites"][1]["properties"][director.code].should eq(user.email)

    end
  end

  describe "GET JSON collection with query parameters" do
    before(:each) do
      get :show, id: collection.id, format: 'json', select_one: 'one'
    end

    it { response.should be_success }
  end

  describe "GET RSS collection" do
    before(:each) do
      get :show, id: collection.id, format: 'rss'
    end

    it { response.should be_success }

    it "should return RSS" do
      rss =  Hash.from_xml response.body

      rss["rss"]["channel"]["title"].should eq(collection.name)

      rss["rss"]["channel"]["item"][0]["title"].should eq(site.name)
      rss["rss"]["channel"]["item"][0]["lat"].should eq(site.lat.to_s)
      rss["rss"]["channel"]["item"][0]["long"].should eq(site.lng.to_s)
      rss["rss"]["channel"]["item"][0]["guid"].should eq(api_site_url site, format: 'rss')


      rss["rss"]["channel"]["item"][0]["properties"].length.should eq(8)

      rss["rss"]["channel"]["item"][0]["properties"][text.code].should eq(site.properties[text.es_code])
      rss["rss"]["channel"]["item"][0]["properties"][numeric.code].should eq(site.properties[numeric.es_code].to_s)
      rss["rss"]["channel"]["item"][0]["properties"][select_one.code].should eq('one')
      rss["rss"]["channel"]["item"][0]["properties"][select_many.code].length.should eq(1)
      rss["rss"]["channel"]["item"][0]["properties"][select_many.code]['option'].length.should eq(2)
      rss["rss"]["channel"]["item"][0]["properties"][select_many.code]['option'][0]['code'].should eq('one')
      rss["rss"]["channel"]["item"][0]["properties"][select_many.code]['option'][1]['code'].should eq('two')
      rss["rss"]["channel"]["item"][0]["properties"][hierarchy.code].should eq('dad')
      rss["rss"]["channel"]["item"][0]["properties"][site_ref.code].should eq(site2.id.to_s)
      rss["rss"]["channel"]["item"][0]["properties"][date.code].should eq('10/24/2012')
      rss["rss"]["channel"]["item"][0]["properties"][director.code].should eq(user.email)


    end

  end

  describe "GET CSV collection" do
    before(:each) do
      get :show, id: collection.id, format: 'csv'
    end

    it { response.should be_success }

    it "should return CSV" do
      csv =  CSV.parse response.body

      csv[0].should eq(['resmap-id', 'name', 'lat', 'long', text.code, numeric.code, select_one.code, select_many.code, hierarchy.code, site_ref.code, date.code, director.code, 'last updated'])
      csv[1].should eq([site2.id.to_s, site2.name, site2.lat.to_s, site2.lng.to_s, "", "", "", "", "", "", "", "", site2.updated_at.to_datetime.rfc822])

      csv[2].should eq([site.id.to_s, site.name, site.lat.to_s, site.lng.to_s, site.properties[text.es_code], site.properties[numeric.es_code].to_s, 'one', 'one, two', 'dad', site2.id.to_s, '10/24/2012', user.email, site.updated_at.to_datetime.rfc822])
    end
  end

  describe "validate query params" do

    it "should validate numeric fields in equal queries" do
      get :show, id: collection.id, format: 'csv', numeric.code => "invalid"
      response.response_code.should be(400)
      response.body.should include("Invalid numeric format in numeric")
    end

    it "should validate numeric fields in other operations" do
      get :show, id: collection.id, format: 'csv', numeric.code => "<=invalid"
      response.response_code.should be(400)
      response.body.should include("Invalid numeric format in numeric")
    end
  end



end
