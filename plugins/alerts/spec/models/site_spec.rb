require 'spec_helper'

describe Site do

  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make(selected_plugins: ['alerts']) }
  let!(:layer) { collection.layers.make }
  let!(:beds_field) { layer.fields.make code: 'beds', kind: 'numeric' }
  let!(:threshold) { collection.thresholds.make is_all_site: true,
    is_all_condition: true,
    conditions: [ {field: beds_field.es_code, op: :gt, value: '10'} ],
    icon: 'foo.png'
  }

  it "set alert in the index properties" do
    site = collection.sites.make :properties => {beds_field.es_code => 100 }

    search = Tire::Search::Search.new site.index_name
    results = search.perform.results
    results.length.should eq(1)
    results[0]["_source"]["alert"].should eq(true)
    results[0]["_source"]["icon"].should eq('foo.png')
  end

  describe "get notification numbers" do
    let!(:telephone) { layer.fields.make code: 'tel', kind: 'phone' }
    let!(:owner) { layer.fields.make code: 'owner', kind: 'user' }
    let!(:user_2) { User.make }
    let!(:alert) { collection.thresholds.make phone_notification: {members: [user.id], fields: [telephone.es_code], users: [owner.es_code]} }
    let!(:site) { collection.sites.make properties: {telephone.es_code => '123456', owner.es_code => user_2.email} }

    it "should include member phone number" do
      site.notification_numbers(alert).should include user.phone_number
    end

    it "should not include other member phone number" do
      site.notification_numbers(alert).should_not include User.make.phone_number
    end

    it "should not include nil phone_number" do
      user.update_attributes phone_number: nil
      site.notification_numbers(alert).should_not include user.phone_number
    end

    context "when alert phone notification is empty hash" do
      before(:each) do
        alert.update_attributes phone_notification: {}
      end

      it "should return empty phone list" do
        site.notification_numbers(alert).should == []
      end
    end

    it "should include site property" do
      site.notification_numbers(alert).should include '123456'
    end

    it "should not include blank string site property" do
      site.update_attributes properties: {telephone.es_code => ''}
      site.notification_numbers(alert).should_not include ''
    end

    it "should include user field phone number" do
      site.notification_numbers(alert).should include user_2.phone_number
    end

    context "when user field does not have phone number" do
      before(:each) do
        user_2.update_attributes phone_number: nil 
      end

      it "should not include nil in" do
        site.notification_numbers(alert).should_not include nil
      end
    end
  end
end
