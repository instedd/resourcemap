require 'spec_helper'

describe SiteMembershipsController do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:layer) { collection.layers.make }
  let!(:field) { layer.fields.make kind: 'user' }

  before(:each) {sign_in user}

  describe "POST set_access" do
    it "should set view access" do
      post :set_access, access: true, type: 'view_access', field_id: field.id, collection_id: collection.id 
      collection.site_memberships.first.view_access.should be true
    end

    it "should remove update access" do
      post :set_access, access: false, type: 'update_access', field_id: field.id, collection_id: collection.id 
      collection.site_memberships.first.update_access.should be false
    end
  end
end
