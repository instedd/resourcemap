require 'spec_helper'

describe ImportWizardsController do
  include Devise::TestHelpers
  render_views

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make) }

  before(:each) {sign_in user}
  let!(:user2) { User.make }
  let!(:membership) { collection.memberships.create! :user_id => user2.id }

  it "should not allow to create a new field to a non-admin user" do
    sign_out user
    membership.set_layer_access :verb => :read, :access => true
    membership.set_layer_access :verb => :write, :access => true
    sign_in user2

    uploaded_file = Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/csv_test.csv'), "text/csv")
    post :upload_csv, collection_id: collection.id, file: uploaded_file, format: 'csv'

    specs = {
      '0' => {name: 'Name', usage: 'name'},
      '1' => {name: 'Lat', usage: 'lat'},
      '2' => {name: 'Lon', usage: 'lng'},
      '3' => {name: 'Beds', usage: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
    }
    post :execute, collection_id: collection.id, columns: specs
    response.response_code.should == 401
  end
end
