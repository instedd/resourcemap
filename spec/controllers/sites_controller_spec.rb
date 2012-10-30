require 'spec_helper'

describe SitesController do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:site) { collection.sites.make }
  let(:numeric) { collection.layers.make.fields.make code: 'n', kind: 'numeric' }

  before(:each) { sign_in user }

  pending 'should not allow setting a non numeric value to a numeric field' do
    post :update_property, site_id: site.id, format: 'json', es_code: numeric.es_code, value: 'not a number'
    response.response_code.should be(400)
  end
end
