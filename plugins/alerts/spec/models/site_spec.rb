require 'spec_helper'

describe Site do

  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make(selected_plugins: ['alerts']) }
  let!(:layer) { collection.layers.make }
  let!(:beds_field) { layer.numeric_fields.make code: 'beds' }
  let!(:threshold) { collection.thresholds.make is_all_site: true,
    is_all_condition: true,
    conditions: [ {field: beds_field.es_code, op: :gt, value: '10'} ],
    color: 'red'
  }

  it "set alert in the index properties" do
    site = collection.sites.make :properties => {beds_field.es_code => 100 }

    search = Tire::Search::Search.new site.index_name
    results = search.perform.results
    results.length.should eq(1)
    results[0]["_source"]["alert"].should eq(true)
    results[0]["_source"]["color"].should eq('red')
  end

  describe "get notification numbers" do
    let!(:telephone) { layer.phone_fields.make code: 'tel'}
    let!(:owner) { layer.user_fields.make code: 'owner'}
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

    context "when alert phone notification is empty" do
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

  describe "get notification emails" do
    let!(:email) { layer.email_fields.make code: 'email'}
    let!(:owner) { layer.user_fields.make code: 'owner' }
    let!(:user_2) { User.make }
    let!(:alert) { collection.thresholds.make email_notification: {members: [user.id], fields: [email.es_code], users: [owner.es_code]} }
    let!(:site) { collection.sites.make properties: {email.es_code => 'info@example.com', owner.es_code => user_2.email} }

    it "should include member email" do
      site.notification_emails(alert).should include user.email
    end

    it "should not include other member email" do
      site.notification_emails(alert).should_not include User.make.email
    end

    context "when alert email notification is empty" do
      before(:each) do
        alert.update_attributes email_notification: {}
      end

      it "should return empty email list" do
        site.notification_emails(alert).should == []
      end
    end

    it "should include site property" do
      site.notification_emails(alert).should include 'info@example.com'
    end

    it "should not include blank string site property" do
      site.update_attributes properties: {email.es_code => ''}
      site.notification_emails(alert).should_not include ''
    end

    it "should include user field email" do
      site.notification_emails(alert).should include user_2.email
    end
  end
end
