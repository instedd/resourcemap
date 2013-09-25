require 'spec_helper'

describe SitesController do
  include Devise::TestHelpers

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make_unsaved) }
  let(:layer) { collection.layers.make }

  let(:site) { collection.sites.make id: 1234}

  let(:text) { layer.text_fields.make code: 'text'}
  let(:numeric) { layer.numeric_fields.make code: 'n' }
  let(:select_one) { layer.select_one_fields.make :code => 'select_one', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  let(:select_many) { layer.select_many_fields.make :code => 'select_many', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
  let(:hierarchy) { layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access }
  let(:site_field) { layer.site_fields.make :code => 'site' }
  let(:date) { layer.date_fields.make :code => 'date' }
  let(:director) { layer.user_fields.make :code => 'user' }
  let(:email_field) { layer.email_fields.make :code => 'email' }

  before(:each) { sign_in user }

  #TODO: Move this functionality to api and rescue validation-exceptions with response_code = 400 and a 'check api doc' message

  it 'should validate format for numeric field' do
    post :update_property, site_id: site.id, format: 'json', es_code: numeric.es_code, value: 'not a number'
    json = JSON.parse response.body
    json["error_message"].should eq("Invalid numeric value in field #{numeric.code}")
    post :update_property, site_id: site.id, format: 'json', es_code: numeric.es_code, value: '2'
    validate_site_property_value(site, numeric, 2)
  end

  it "should validate format for date field  in mm/dd/yyyy format" do
    post :update_property, site_id: site.id, format: 'json', es_code: date.es_code, value: '11/27/2012'
    validate_site_property_value(site, date, "2012-11-27T00:00:00Z")
    post :update_property, site_id: site.id, format: 'json', es_code: date.es_code, value: "117"
    json = JSON.parse response.body
    json["error_message"].should eq("Invalid date value in field #{date.code}. The configured date format is mm/dd/yyyy.")
  end

  it "should validate format for hierarchy field" do
    post :update_property, site_id: site.id, format: 'json', es_code: hierarchy.es_code, value: "101"
    validate_site_property_value(site, hierarchy, "101")
    post :update_property, site_id: site.id, format: 'json', es_code: hierarchy.es_code, value: "Dad"
    json = JSON.parse response.body
    json["error_message"].should eq("Invalid hierarchy option in field #{hierarchy.code}")
  end

  it "should validate format for select_one field" do
    post :update_property, site_id: site.id, format: 'json', es_code: select_one.es_code, value: "1"
    validate_site_property_value(site, select_one, 1)
    post :update_property, site_id: site.id, format: 'json', es_code: select_one.es_code, value: "one"
    json = JSON.parse response.body
    json["error_message"].should eq("Invalid option in field #{select_one.code}")
  end

  it "should validate format for select_many field" do
    post :update_property, site_id: site.id, format: 'json', es_code: select_many.es_code, value: ["1"]
    validate_site_property_value(site, select_many, [1])
    post :update_property, site_id: site.id, format: 'json', es_code: select_many.es_code, value: ["2", "1"]
    validate_site_property_value(site, select_many, [2, 1])
    post :update_property, site_id: site.id, format: 'json', es_code: select_many.es_code, value: "2, 1"
    validate_site_property_value(site, select_many, [2, 1])
    post :update_property, site_id: site.id, format: 'json', es_code: select_many.es_code, value: "[two,]"
    json = JSON.parse response.body
    json["error_message"].should eq("Invalid option '[two' in field #{select_many.code}")
    post :update_property, site_id: site.id, format: 'json', es_code: select_many.es_code, value: "two,one"
    json = JSON.parse response.body
    json["error_message"].should eq("Invalid option 'two' in field #{select_many.code}")
  end

  it "should validate format for site field" do
    post :update_property, site_id: site.id, format: 'json', es_code: site_field.es_code, value: "1234"
    validate_site_property_value(site, site_field, "1234")
    post :update_property, site_id: site.id, format: 'json', es_code: site_field.es_code, value: 23
    json = JSON.parse response.body
    json["error_message"].should eq("Non-existent site-id in field #{site_field.code}")
  end

  it "should validate format for user field" do
    post :update_property, site_id: site.id, format: 'json', es_code: director.es_code, value: user.email
    validate_site_property_value(site, director, user.email)
    post :update_property, site_id: site.id, format: 'json', es_code: director.es_code, value: "inexisting@email.com"
    json = JSON.parse response.body
    json["error_message"].should eq("Non-existent user email address in field #{director.code}")
  end

  it "should validate format for email field" do
    post :update_property, site_id: site.id, format: 'json', es_code: email_field.es_code, value: "valid@email.com"
    validate_site_property_value(site, email_field, "valid@email.com")
    post :update_property, site_id: site.id, format: 'json', es_code: email_field.es_code, value: "v3@@e.mail.c.om"
    json = JSON.parse response.body
    json["error_message"].should eq("Invalid email address in field #{email_field.code}")
  end

  it 'should create a new site' do
    site_params = {:name => "new site", :lat => "-7.338135", :lng => "29.836455", :properties => {
      text.es_code => "new text",
      numeric.es_code => "123",
      select_one.es_code => 1,
      select_many.es_code => [1,2],
      hierarchy.es_code => "101",
      site_field.es_code=> site.id,
      date.es_code => "2013-02-05T00:00:00Z",
      director.es_code => user.email,
      email_field.es_code => "myemail@mail.com" }}.to_json
    post :create, {:collection_id => collection.id, :site => site_params}

    response.should be_success
    new_site = Site.find_by_name "new site"


    validate_site_property_value(new_site, text, "new text")
    validate_site_property_value(new_site, numeric, 123)
    validate_site_property_value(new_site, select_one, 1)
    validate_site_property_value(new_site, select_many, [1,2])
    validate_site_property_value(new_site, hierarchy, "101")
    validate_site_property_value(new_site, site_field, site.id)
    validate_site_property_value(new_site, date, "2013-02-05T00:00:00Z")
    validate_site_property_value(new_site, director, user.email)
    validate_site_property_value(new_site, email_field, "myemail@mail.com")
  end

  describe 'updating site' do

    it 'should not be allowed to full update a site if the user is not the collection admin' do
      sign_out user

      member = User.make
      membership = Membership.make collection: collection, user: member, admin: false
      sign_in member

      site_params = {:name => "new site"}.to_json
      post :update, {:collection_id => collection.id, :id => site.id, :site => site_params }

      response.status.should eq(403)
    end

    it 'should update only name' do
      site_params = {:name => "new site"}.to_json
      post :partial_update, {:collection_id => collection.id, :id => site.id, :site => site_params }

      response.should be_success
      modified_site = Site.find_by_name "new site"
      modified_site.should be
    end

    it 'should not be allowed to update name if user does not have permission' do
      sign_out user

      member = User.make
      membership = Membership.make collection: collection, user: member, admin: false
      membership.set_access(object: 'name', new_action: 'read')

      sign_in member

      site_params = {:name => "new site"}.to_json
      post :partial_update, {:collection_id => collection.id, :id => site.id, :site => site_params }

      response.status.should eq(403)
      Site.find_by_name("new site").should be_nil
    end

    it 'should be able to delete location' do
      site_params = {:lat => nil, :lng => nil}.to_json
      post :partial_update, {:collection_id => collection.id, :id => site.id, :site => site_params }

      response.should be_success
      modified_site = Site.find_by_name site.name
      modified_site.lat.should be(nil)
      modified_site.lng.should be(nil)
    end

    it 'should not be allowed to update location if user does not have permission' do
      sign_out user

      member = User.make
      membership = Membership.make collection: collection, user: member, admin: false
      membership.set_access(object: 'location', new_action: 'read')
      previous_lat = site.lat
      previous_lng = site.lng

      sign_in member

      site_params = {:lat => nil, :lng => nil}.to_json
      post :partial_update, {:collection_id => collection.id, :id => site.id, :site => site_params }

      response.status.should eq(403)
      site.reload
      site.lat.should eq(previous_lat)
      site.lng.should eq(previous_lng)
    end

    it 'should not delete existing properties when only the name is modified' do
      site.properties[text.es_code] = "existing value"
      site.save!

      site_params = {:name => "new site"}.to_json
      post :partial_update, {:collection_id => collection.id, :id => site.id, :site => site_params }

      modified_site = Site.find_by_name "new site"
      modified_site.should be
      modified_site.properties[text.es_code].should eq("existing value")
    end

    it 'should not delete existing properties when only the one of them is modified' do
      site.properties[text.es_code] = "existing value"
      site.properties[numeric.es_code] = 12

      site.save!

      site_params = {:properties => {text.es_code => "new value"}}.to_json
      post :partial_update, {:collection_id => collection.id, :id => site.id, :site => site_params }

      modified_site = site.reload
      modified_site.properties[text.es_code].should eq("new value")
      modified_site.properties[numeric.es_code].should eq(12)
    end

    it 'should not be allowed to update a property if user does not have permission' do
      site.properties[text.es_code] = "existing value"
      site.save!

      sign_out user

      member = User.make
      membership = Membership.make collection: collection, user: member, admin: false
      LayerMembership.make layer: text.layer, membership: membership, read: false

      sign_in member

      site_params = {:properties => {text.es_code => "new value"}}.to_json
      post :partial_update, {:collection_id => collection.id, :id => site.id, :site => site_params }

      response.status.should eq(403)
      site.reload
      site.properties[text.es_code].should eq("existing value")
    end

    it 'should update a single property' do
      site_params = {:properties => { text.es_code => "new text" }}.to_json
      post :partial_update, {:collection_id => collection.id, :id => site.id, :site => site_params }

      response.should be_success
      new_site = Site.find_by_name site.name
      new_site.properties[text.es_code.to_s]
    end
  end

  it "can destroy site" do
    delete :destroy, id: site.id, collection_id: collection.id

    Site.find_by_id(site.id).should be_nil
  end

  def validate_site_property_value(site, property, value)
    site.reload
    site.properties["#{property.es_code}"].should eq(value)
  end

  describe 'analytic' do
    it 'should changed user.site_count by 1'  do
      expect {
        post :create, site: "{\"name\":\"site_01\",\"lat\":8.932599568335238,\"lng\":99.27246091406255,\"properties\":{}}", collection_id: collection.id
      }.to change{
        u = User.find user
        u.site_count
      }.from(0).to(1)
    end
  end

  describe 'yes_no with auto_reset' do
    let!(:auto_reset_field) { layer.yes_no_fields.make :code => 'flag', :config => { 'auto_reset' => true } }

    describe 'create new site' do
      before(:each) do
        site_params = {:name => "new site"}.to_json
        @response = post :create, {:collection_id => collection.id, :site => site_params}
      end

      it "should be success" do
        @response.should be_success
      end

      it "should reset on create" do
        new_site = Site.find_by_name "new site"
        new_site.properties[auto_reset_field.es_code.to_s].should be_false
      end
    end

    describe 'update site' do
      before(:each) do
        site.properties[auto_reset_field.es_code] = true
        site.save!

        site_params = {:name => "new site name"}.to_json
        @response = post :partial_update, { :collection_id => collection.id, :id => site.id, :site => site_params }
      end

      it "should be success" do
        @response.should be_success
      end

      it "should reset field" do
        new_site = Site.find_by_name "new site name"
        new_site.properties[auto_reset_field.es_code.to_s].should be_false
      end
    end

    describe 'update site without changing' do
      before(:each) do
        site.properties[auto_reset_field.es_code] = true
        site.save!

        site_params = {:name => site.name}.to_json
        @response = post :partial_update, { :collection_id => collection.id, :id => site.id, :site => site_params }
      end

      it "should be success" do
        @response.should be_success
      end

      it "should not reset field" do
        new_site = Site.find_by_name site.name
        new_site.properties[auto_reset_field.es_code.to_s].should be_true
      end
    end

    describe 'update site forcing auto_reset_value' do
      before(:each) do
        site_params = {:name => "new site name", :properties => {
          auto_reset_field.es_code => true
        }}.to_json
        @response = post :partial_update, { :collection_id => collection.id, :id => site.id, :site => site_params }
      end

      it "should be success" do
        @response.should be_success
      end

      it "should reset field" do
        new_site = Site.find_by_name "new site name"
        new_site.properties[auto_reset_field.es_code.to_s].should be_false
      end
    end

    describe 'update other site property' do
      before(:each) do
        post :update_property, site_id: site.id, format: 'json', es_code: numeric.es_code, value: '2'
      end

      it "should update property" do
        validate_site_property_value(site, numeric, 2)
      end

      it "should reset field" do
        validate_site_property_value(site, auto_reset_field, false)
      end
    end

    describe 'update auto_reset site property' do
      before(:each) do
        post :update_property, site_id: site.id, format: 'json', es_code: auto_reset_field.es_code, value: true
      end

      it "should update property" do
        validate_site_property_value(site, auto_reset_field, true)
      end
    end
  end
end
