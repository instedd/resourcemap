require 'spec_helper'

describe ImportWizardsController, :type => :controller do
  include Devise::TestHelpers
  render_views

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make) }

  before(:each) {sign_in user}
  let(:user2) { User.make }
  let(:membership) { collection.memberships.create! :user_id => user2.id }
  let(:layer) { collection.layers.make }

  it "should not allow to create a new field to a non-admin user" do
    sign_out user
    membership.activity_user = user2
    membership.set_layer_access :verb => :read, :access => true, :layer_id => layer.id
    membership.set_layer_access :verb => :write, :access => true, :layer_id => layer.id
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
    expect(response.response_code).to eq(401)
    ImportWizard.delete_files(user2, collection)
  end

  it "should get job status of an enqued job" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Lat', 'Lon']
      csv << ['Foo', '1.2', '3.4']
      csv << ['Bar', '5.6', '7.8']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string
    ImportWizard.mark_job_as_pending user, collection

    get :job_status, collection_id: collection.id
    json_response = JSON.parse response.body
    expect(json_response["status"]).to eq("pending")
    ImportWizard.delete_files(user, collection)
  end

  it "should not fail when quering job status of a non enqued job" do
    get :job_status, collection_id: collection.id
    expect(response.status).to eq(404)
    json_response = JSON.parse response.body
    expect(json_response["status"]).to eq("not_found")
  end
end
