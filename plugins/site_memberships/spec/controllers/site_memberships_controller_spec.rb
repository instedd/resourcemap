require 'spec_helper'

describe SiteMembershipsController do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:layer) { collection.layers.make }
  let!(:field) { layer.fields.make kind: 'user' }

  before(:each) {sign_in user}

  describe "POST set_access" do
    pending "should set view access" do
      post :set_access, access: true, type: 'view_access', field_id: field.id, collection_id: collection.id
      collection.site_memberships.first.view_access.should be true
    end

    pending "should revoke update access" do
      post :set_access, access: false, type: 'update_access', field_id: field.id, collection_id: collection.id
      collection.site_memberships.first.update_access.should be false
    end

    context "when user is not collection admin" do
      let!(:membership) { collection.memberships.first }

      before(:each) do
        membership.update_attributes admin: false
        post :set_access, access: true, type: 'view_access', field_id: field.id, collection_id: collection.id
      end

      it "should not set view access" do
        collection.site_memberships.count.should == 0
      end

      it "should respond unauthorized header" do
        response.status.should == 401
      end
    end
  end
end
