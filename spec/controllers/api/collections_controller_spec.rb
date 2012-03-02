require 'spec_helper'

describe Api::CollectionsController do

  let!(:collection) { Collection.make }

  describe "GET collection" do
    before(:each) do
      get :show, format: 'rss', id: collection.id
    end

    it { response.should be_success }
    it "should response RSS" do
      response.content_type.should eq 'application/rss+xml'
    end
  end
end
