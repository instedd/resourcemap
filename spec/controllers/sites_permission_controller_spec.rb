require 'spec_helper'

describe SitesPermissionController, :type => :controller do
  include Devise::TestHelpers

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make_unsaved) }
  before(:each) { sign_in user }

  describe 'POST create' do
    it 'should response ok' do
      post :create, "sites_permission" => {"user_id" => user.id}, "collection_id" => collection.id
      expect(response.body).to eq("\"ok\"")
    end
  end

  describe 'GET index' do
    let(:membership) { collection.memberships[0] }
    let(:read_sites_permission) { membership.create_read_sites_permission all_sites: true }
    let(:write_sites_permission) { membership.create_write_sites_permission all_sites: false, some_sites: [{id: 1, name: 'Bayon clinic'}] }

    before(:each) { get :index, "collection_id" => collection.id }
    it "should response include read sites permission" do
      expect(response.body).to include "\"read\":#{read_sites_permission.to_json}"
    end

    skip "should response include write sites permission" do
      expect(response.body).to include "\"write\":#{write_sites_permission.to_json}"
    end
  end
end
