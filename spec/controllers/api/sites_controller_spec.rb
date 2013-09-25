require 'spec_helper'

describe Api::SitesController do
  include Devise::TestHelpers

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make_unsaved) }

  before(:each) { sign_in user }

  describe "GET site" do
    let(:site) { collection.sites.make }

    before(:each) do
      get :show, id: site.id, format: 'rss'
    end

    it { response.should be_success }
    it "should response RSS" do
      response.content_type.should eq 'application/rss+xml'
    end
  end

  describe "Histories" do
    let(:site2) { collection.sites.make name: "New name 0" }

    before(:each) do
      10.times do |i|
        site2.name = "New name #{i+1}"
        site2.save!
      end
    end

    it "should get all histories in JSON" do
      get :histories, collection_id: site2.collection_id, id: site2.id, format: 'json'
      response.should be_success
      json = JSON.parse response.body
      json.length.should eq(11)
      json.each_with_index do |site, index|
        site["name"].should eq("New name #{index}")
        site["version"].should eq(index+1)
      end
    end

    it "should get a single history by version" do
      get :histories, collection_id: site2.collection_id, id: site2.id, version: 3, format: 'json'
      response.should be_success
      json = JSON.parse response.body
      json.length.should eq(1)
      json[0]["name"].should eq("New name 2")
      json[0]["version"].should eq(3)
    end
  end
end
