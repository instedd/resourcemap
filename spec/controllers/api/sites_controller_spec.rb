require 'spec_helper'

describe Api::SitesController do
  include Devise::TestHelpers

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make_unsaved) }

  before(:each) { sign_in user }

  describe "GET site" do
    let(:site) { collection.sites.make }

    before(:each) do
      get :show, id: site.id, format: 'rss'
    end

    it { response.should be_success }
    it "should response RSS" do
      response.content_type.should eq 'application/rss+xml'
    end
  end

  describe "Histories" do
    let(:site2) { collection.sites.make name: "New name 0" }

    before(:each) do
      10.times do |i|
        site2.name = "New name #{i+1}"
        site2.save!
      end
    end

    it "should get all histories in JSON" do
      get :histories, format: 'json', collection_id: site2.collection_id, id: site2.id
      response.should be_success
      json = JSON.parse response.body
      json.length.should eq(11)
      json.each_with_index do |site, index|
        site["name"].should eq("New name #{index}")
        site["version"].should eq(index+1)
      end
    end

    it "should get a single history by version" do
      get :histories, format: 'json', collection_id: site2.collection_id, id: site2.id, version: 3
      response.should be_success
      json = JSON.parse response.body
      json.length.should eq(1)
      json[0]["name"].should eq("New name 2")
      json[0]["version"].should eq(3)
    end
  end

  context "update single property" do
    let(:site) { collection.sites.make id: 1234}
    let(:layer) { collection.layers.make }
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

    it 'should validate format for numeric field' do
      post :update_property, id: site.id, es_code: numeric.es_code, value: 'not a number'
      json = JSON.parse response.body
      json["message"].should include("Invalid numeric value in field #{numeric.code}")
      post :update_property, id: site.id, es_code: numeric.es_code, value: '2'
      validate_site_property_value(site, numeric, 2)
    end

    it "should validate format for date field  in mm/dd/yyyy format" do
      post :update_property, id: site.id, es_code: date.es_code, value: '11/27/2012'
      validate_site_property_value(site, date, "2012-11-27T00:00:00Z")
      post :update_property, id: site.id, es_code: date.es_code, value: "117"
      json = JSON.parse response.body
      json["message"].should include("Invalid date value in field #{date.code}. The configured date format is mm/dd/yyyy.")
    end

    it "should validate format for hierarchy field" do
      post :update_property, id: site.id, es_code: hierarchy.es_code, value: "101"
      validate_site_property_value(site, hierarchy, "101")
      post :update_property, id: site.id, es_code: hierarchy.es_code, value: "Dad"
      json = JSON.parse response.body
      json["message"].should include("Invalid hierarchy option 'Dad' in field '#{hierarchy.code}'")
    end

    it "should validate format for select_one field" do
      post :update_property, id: site.id, es_code: select_one.es_code, value: "1"
      validate_site_property_value(site, select_one, 1)
      post :update_property, id: site.id, es_code: select_one.es_code, value: "one"
      json = JSON.parse response.body
      json["message"].should include("Invalid option in field #{select_one.code}")
    end

    it "should validate format for select_many field" do
      post :update_property, id: site.id, es_code: select_many.es_code, value: ["1"]
      validate_site_property_value(site, select_many, [1])
      post :update_property, id: site.id, es_code: select_many.es_code, value: ["2", "1"]
      validate_site_property_value(site, select_many, [2, 1])
      post :update_property, id: site.id, es_code: select_many.es_code, value: "2, 1"
      validate_site_property_value(site, select_many, [2, 1])
      post :update_property, id: site.id, es_code: select_many.es_code, value: "[two,]"
      json = JSON.parse response.body
      json["message"].should include("Invalid option '[two' in field #{select_many.code}")
      post :update_property, id: site.id, es_code: select_many.es_code, value: "two,one"
      json = JSON.parse response.body
      json["message"].should include("Invalid option 'two' in field #{select_many.code}")
    end

    it "should validate format for site field" do
      post :update_property, id: site.id, es_code: site_field.es_code, value: "1234"
      validate_site_property_value(site, site_field, "1234")
      post :update_property, id: site.id, es_code: site_field.es_code, value: 23
      json = JSON.parse response.body
      json["message"].should include("Non-existent site-id in field #{site_field.code}")
    end

    it "should validate format for user field" do
      post :update_property, id: site.id, es_code: director.es_code, value: user.email
      validate_site_property_value(site, director, user.email)
      post :update_property, id: site.id, es_code: director.es_code, value: "inexisting@email.com"
      json = JSON.parse response.body
      json["message"].should include("Non-existent user email address in field #{director.code}")
    end

    it "should validate format for email field" do
      post :update_property, id: site.id, es_code: email_field.es_code, value: "valid@email.com"
      validate_site_property_value(site, email_field, "valid@email.com")
      post :update_property, id: site.id, es_code: email_field.es_code, value: "v3@@e.mail.c.om"
      json = JSON.parse response.body
      json["message"].should include("Invalid email address in field #{email_field.code}")
    end

    it "should increase the site version when updating a single property" do
      site_version = site.version
      post :update_property, id: site.id, es_code: email_field.es_code, value: "valid@email.com"
      json = JSON.parse response.body
      json["version"].should eq(site_version+1)
    end
  end

  def validate_site_property_value(site, property, value)
    site.reload
    site.properties["#{property.es_code}"].should eq(value)
  end
end
