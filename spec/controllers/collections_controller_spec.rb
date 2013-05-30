require 'spec_helper'

describe CollectionsController do
  include Devise::TestHelpers
  render_views
  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make public: false) }

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

        text = layer.text_fields.make :code => 'text'
        numeric = layer.numeric_fields.make :code => 'numeric'

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

  describe "Permissions" do
    let!(:public_collection) { user.create_collection(Collection.make public: false) }
    let!(:other_user) { User.make }


    it 'should return forbidden on delete if user is not collection admin' do
      sign_out user
      sign_in other_user
      delete :destroy, id: collection.id
      response.status.should eq(403)
    end

    it 'should return forbidden on delete if user is not collection admin' do
      sign_out user
      sign_in other_user
      post :create_snapshot, id: collection.id, snapshot: {name: 'my snapshot'}
      response.status.should eq(403)
    end

    it 'should redirect to login if a guest user tries to read a non-public collection' do
      sign_out user
      # Nobody signs in. 
      # We are emulating the use case in which a guest user tries to read private collction
      post :index, id: collection.id
      response.status.should eq(401)
    end

    it 'should read a public collection if user is guest' do
      sign_out user
      post :index, id: public_collection.id
      response.status.should eq(200)
    end
  end


  describe "analytic" do 
    it 'should changed user.collection_count by 1' do
      expect{ 
        post :create, collection: { name: 'collection_1', icon: 'default'}
      }.to change{
        u = User.find user
        u.collection_count
      }.from(0).to(1)
   
    end
  end
end
