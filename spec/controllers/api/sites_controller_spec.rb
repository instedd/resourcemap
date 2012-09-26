require 'spec_helper'

describe Api::SitesController do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:site) { collection.sites.make }

  before(:each) { sign_in user }

  describe "GET site" do
    before(:each) do
      get :show, id: site.id, format: 'rss'
    end

    #TODO: This will be fixed soon
    pending { response.should be_success }
    it "should response RSS" do
      response.content_type.should eq 'application/rss+xml'
    end
  end
end
