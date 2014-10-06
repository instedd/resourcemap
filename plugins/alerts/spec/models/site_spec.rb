require 'spec_helper'

describe Site, :type => :model do

  let(:user) { User.make }
  let(:collection) { user.create_collection Collection.make(selected_plugins: ['alerts']) }
  let(:layer) { collection.layers.make }
  let(:beds_field) { layer.numeric_fields.make code: 'beds' }
  let!(:threshold) { collection.thresholds.make is_all_site: true,
    is_all_condition: true,
    conditions: [ {field: beds_field.es_code, op: :gt, value: '10'} ],
    color: 'red'
  }

  it "set alert in the index properties" do
    site = collection.sites.make :properties => {beds_field.es_code => 100 }

    client = Elasticsearch::Client.new
    results = client.search index: site.index_name
    results = results["hits"]["hits"]
    expect(results.length).to eq(1)
    expect(results[0]["_source"]["alert"]).to eq(true)
    expect(results[0]["_source"]["color"]).to eq('red')
  end

  describe "get notification numbers" do
    let(:telephone) { layer.phone_fields.make code: 'tel'}
    let(:owner) { layer.user_fields.make code: 'owner'}
    let(:user_2) { User.make }
    let!(:membership) { collection.memberships.create! :user_id => user_2.id }
    let(:alert) { collection.thresholds.make phone_notification: {members: [user.id], fields: [telephone.es_code], users: [owner.es_code]} }
    let(:site) { collection.sites.make properties: {telephone.es_code => '123456', owner.es_code => user_2.email} }

    it "should include member phone number" do
      expect(site.notification_numbers(alert)).to include user.phone_number
    end

    it "should not include other member phone number" do
      expect(site.notification_numbers(alert)).not_to include User.make.phone_number
    end

    it "should not include nil phone_number" do
      user.update_attributes phone_number: nil
      expect(site.notification_numbers(alert)).not_to include user.phone_number
    end

    context "when alert phone notification is empty" do
      before(:each) do
        alert.update_attributes phone_notification: {}
      end

      it "should return empty phone list" do
        expect(site.notification_numbers(alert)).to eq([])
      end
    end

    it "should include site property" do
      expect(site.notification_numbers(alert)).to include '123456'
    end

    it "should not include blank string site property" do
      site.update_attributes properties: {telephone.es_code => ''}
      expect(site.notification_numbers(alert)).not_to include ''
    end

    it "should include user field phone number" do
      expect(site.notification_numbers(alert)).to include user_2.phone_number
    end

    context "when user field does not have phone number" do
      before(:each) do
        user_2.update_attributes phone_number: nil
      end

      it "should not include nil in" do
        expect(site.notification_numbers(alert)).not_to include nil
      end
    end
  end

  describe "get notification emails" do
    let(:email) { layer.email_fields.make code: 'email'}
    let(:owner) { layer.user_fields.make code: 'owner' }
    let(:user_2) { User.make }
    let!(:membership) { collection.memberships.create! :user_id => user_2.id }
    let(:alert) { collection.thresholds.make email_notification: {members: [user.id], fields: [email.es_code], users: [owner.es_code]} }
    let(:site) { collection.sites.make properties: {email.es_code => 'info@example.com', owner.es_code => user_2.email} }

    it "should include member email" do
      expect(site.notification_emails(alert)).to include user.email
    end

    it "should not include other member email" do
      expect(site.notification_emails(alert)).not_to include User.make.email
    end

    context "when alert email notification is empty" do
      before(:each) do
        alert.update_attributes email_notification: {}
      end

      it "should return empty email list" do
        expect(site.notification_emails(alert)).to eq([])
      end
    end

    it "should include site property" do
      expect(site.notification_emails(alert)).to include 'info@example.com'
    end

    it "should not include blank string site property" do
      site.update_attributes properties: {email.es_code => ''}
      expect(site.notification_emails(alert)).not_to include ''
    end

    it "should include user field email" do
      expect(site.notification_emails(alert)).to include user_2.email
    end
  end
end
