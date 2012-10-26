require 'spec_helper'

describe CollectionsController do
  include Devise::TestHelpers
  render_views

  let!(:user) { User.make }
  let!(:user2) { User.make }
  let!(:collection) { user.create_collection(Collection.make) }

  before(:each) {sign_in user}


  it "should generate error description form preprocessed hierarchy list" do
    hierarchy_csv = [
      {:order=>1, :error=>"Wrong format.", :error_description=>"Invalid column number"},
      {:order=>2, :id=>"2", :name=>"dad", :sub=>[{:order=>3, :id=>"3", :name=>"son"}]} ]

    res = CollectionsController.generate_error_description_list(hierarchy_csv)

    res.should == "Error: Wrong format. Invalid column number in line 1."
  end

  it "should generate error description form invalid hierarchy list" do
    hierarchy_csv = [{:error=>"Illegal quoting in line 3."}]

    res = CollectionsController.generate_error_description_list(hierarchy_csv)

    res.should == "Error: Illegal quoting in line 3."
  end

  it "should generate error description html form invalid hierarchy list with >1 errors" do
    hierarchy_csv = [
      {:order=>1, :error=>"Wrong format.", :error_description=>"Invalid column number"},
      {:order=>2, :error=>"Wrong format.", :error_description=>"Invalid column number"} ]


    res = CollectionsController.generate_error_description_list(hierarchy_csv)

    res.should == "Error: Wrong format. Invalid column number in line 1.<br/>Error: Wrong format. Invalid column number in line 2."
  end

  describe "get ES resutls" do
      before(:each) do
        layer = collection.layers.make

        text = layer.fields.make :code => 'text', :kind => 'text'
        numeric = layer.fields.make :code => 'numeric', :kind => 'numeric'

        @site1 = collection.sites.make :name => "site1", :properties => {text.es_code => 'foo', numeric.es_code => 1 }
        @site2 = collection.sites.make :name => "osite2", :properties => {text.es_code => 'bar', numeric.es_code => 2 }
      end

    it "should get json of all field names and codes in a collection" do
      get :sites_by_term, collection_id: collection.id, format: 'json'

      json = JSON.parse response.body
      json.length.should eq(2)
      json[0]["id"].should eq(@site2.id)
      json[0]["name"].should eq(@site2.name)
      json[0]["value"].should eq(@site2.name)
      json[1]["id"].should eq(@site1.id)
      json[1]["name"].should eq(@site1.name)
      json[1]["value"].should eq(@site1.name)
    end

    it "should filter by name in a collection" do
      get :sites_by_term, collection_id: collection.id, format: 'json', term: "o"

      json = JSON.parse response.body
      json.length.should eq(1)
      json[0]["id"].should eq(@site2.id)
      json[0]["name"].should eq(@site2.name)
      json[0]["value"].should eq(@site2.name)
    end

  end

  describe "import wizard" do
    it "should do something" do
      sign_out user
      membership = collection.memberships.create! :user_id => user2.id
      membership.set_layer_access :verb => :read, :access => true
      membership.set_layer_access :verb => :write, :access => true
      sign_in user2

      uploaded_file = Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/csv_test.csv'), "text/csv")
      post :import_wizard_upload_csv, collection_id: collection.id, file: uploaded_file, format: 'csv'

      specs = {
        '0' => {name: 'Name', usage: 'name'},
        '1' => {name: 'Lat', usage: 'lat'},
        '2' => {name: 'Lon', usage: 'lng'},
        '3' => {name: 'Beds', usage: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      }
      post :import_wizard_execute, collection_id: collection.id, columns: specs
      response.response_code.should == 401
    end
  end

end
