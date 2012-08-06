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

  let!(:site) { collection.sites.make :properties => {text.es_code => 'foo', numeric.es_code => 1, select_one.es_code => 1, select_many.es_code => [1, 2]} }


  before(:each) { sign_in user }

  describe "GET JSON collection" do
    before(:each) do
      get :show, id: collection.id, format: 'json'
    end

    it { response.should be_success }

    it "should return JSON" do
      json = JSON.parse response.body
      json["name"].should eq(collection.name)
      json["sites"].length.should eq(1)
      json["sites"][0]["id"].should eq(site.id)
      json["sites"][0]["name"].should eq(site.name)
      json["sites"][0]["lat"].should eq(site.lat)
      json["sites"][0]["long"].should eq(site.lng)

      json["sites"][0]["properties"].length.should eq(4)

      json["sites"][0]["properties"][text.code].should eq(site.properties[text.es_code])
      json["sites"][0]["properties"][numeric.code].should eq(site.properties[numeric.es_code])
      json["sites"][0]["properties"][select_one.code].should eq('one')
      json["sites"][0]["properties"][select_many.code].should eq(['one', 'two'])
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
      rss["rss"]["channel"]["item"]["title"].should eq(site.name)
      rss["rss"]["channel"]["item"]["lat"].should eq(site.lat.to_s)
      rss["rss"]["channel"]["item"]["long"].should eq(site.lng.to_s)
      rss["rss"]["channel"]["item"]["guid"].should eq(api_site_url site, format: 'rss')


      rss["rss"]["channel"]["item"]["properties"].length.should eq(4)

      rss["rss"]["channel"]["item"]["properties"][text.code].should eq(site.properties[text.es_code])
      rss["rss"]["channel"]["item"]["properties"][numeric.code].should eq(site.properties[numeric.es_code].to_s)
      rss["rss"]["channel"]["item"]["properties"][select_one.code].should eq('one')
      rss["rss"]["channel"]["item"]["properties"][select_many.code].length.should eq(1)
      rss["rss"]["channel"]["item"]["properties"][select_many.code]['option'].length.should eq(2)
      rss["rss"]["channel"]["item"]["properties"][select_many.code]['option'][0]['code'].should eq('one')
      rss["rss"]["channel"]["item"]["properties"][select_many.code]['option'][1]['code'].should eq('two')
    end
  end

  describe "GET CSV collection" do
    before(:each) do
      get :show, id: collection.id, format: 'csv'
    end

    it { response.should be_success }

    it "should return CSV" do
      csv =  CSV.parse response.body

      csv[0].should eq(['resmap-id', 'name', 'lat', 'long', text.code, numeric.code, select_one.code, select_many.code, 'last updated'])
      csv[1].should eq([site.id.to_s, site.name, site.lat.to_s, site.lng.to_s, site.properties[text.es_code], site.properties[numeric.es_code].to_s, 'one', 'one, two', site.updated_at.to_datetime.rfc822])
    end
  end
end
