require 'spec_helper'

describe Api::SitesController do

  let!(:site) { Site.make }

  describe "GET site" do
    before(:each) do
      get :show, format: 'rss', id: site.id
    end

    it { response.should be_success }
    it "should response RSS" do
      response.content_type.should eq 'application/rss+xml'
    end
  end
end
