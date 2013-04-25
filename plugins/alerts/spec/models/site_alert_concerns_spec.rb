require 'spec_helper'

describe Site::AlertConcerns do 
  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make }
  let!(:layer) { collection.layers.make }
  let!(:bed_field) { layer.numeric_fields.make :code => 'bed' }
  let!(:phone_field) { layer.phone_fields.make :code => 'phone' } 
  let!(:email_field) { layer.email_fields.make :code => 'email' } 
  let!(:user_field) { layer.user_fields.make :code => 'user' } 
  let!(:site1) { collection.sites.make :properties => { bed_field.es_code => 15, phone_field.es_code => '123456', email_field.es_code => 'foo@example.com', user_field.es_code => user.email}} 
  let!(:user_2) { User.make }
  let!(:user_3) { User.make }

  before(:each) do
    collection.memberships.create! :user_id => user_2.id
    collection.memberships.create! :user_id => user_3.id
  end
  
  describe "add new site" do 
    describe "when hit threshold" do
      describe "send email and sms to all selected users_field" do 
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {users: [user_field.es_code]}, phone_notification: {users: [user_field.es_code]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :gt, value: 10 ]}
        let!(:site) {collection.sites.make :properties => {bed_field.es_code => 15, user_field.es_code => user.email}}
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([user.phone_number], threshold.message_notification, 'smart', collection.id).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([user.email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end 

      describe "send email and sms to all selected all members" do
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {members: [user.id]}, phone_notification: {members: [user.id]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
        let!(:site) {collection.sites.make :properties => {bed_field.es_code => 5}}
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([user.phone_number], threshold.message_notification, 'smart', collection.id).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([user.email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end

      describe "send email and sms to all selected fields" do
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {fields: [email_field.es_code]}, phone_notification: {fields: [phone_field.es_code]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
        let!(:site) {collection.sites.make :properties => {bed_field.es_code => 5, phone_field.es_code => '123456', email_field.es_code => 'foo@example.com'}}
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued(['123456'], threshold.message_notification, 'smart', collection.id).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued(['foo@example.com'], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end
      
      describe "send email and sms to all selected fields, members and users" do
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {members: [user.id], fields: [email_field.es_code], users: [user_field.es_code]}, phone_notification: { members: [user.id], fields: [phone_field.es_code], users: [user_field.es_code]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
        let!(:site) {collection.sites.make :properties => {bed_field.es_code => 5, phone_field.es_code => '123456', email_field.es_code => 'foo@example.com', user_field.es_code => user_2.email}}
        
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([user.phone_number, '123456', user_2.phone_number], threshold.message_notification, 'smart', collection.id).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([user.email, 'foo@example.com', user_2.email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end
    end
  end
  
  describe "edit site" do
    describe "when hit threshold" do
      describe "send email and sms to all selected users_field" do 
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {users: [user_field.es_code]}, phone_notification: {users: [user_field.es_code]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
        before(:each) do
          ResqueSpec.reset!
          site1.properties = {bed_field.es_code => 5, user_field.es_code => user_2.email}
          site1.save!
        end
        
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([user_2.phone_number], threshold.message_notification, 'smart', collection.id).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([user_2.email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end 

      describe "send email and sms to all selected members" do
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {members: [user.id]}, phone_notification: {members: [user.id]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 20 ]}
        before(:each) do
          ResqueSpec.reset!
          site1.properties = {bed_field.es_code => 15}
          site1.save!
        end
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([user.phone_number], threshold.message_notification, 'smart', collection.id).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([user.email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end

      describe "send email and sms to all selected fields" do
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {fields: [email_field.es_code]}, phone_notification: {fields: [phone_field.es_code]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
        before(:each) do
          ResqueSpec.reset!
          site1.properties = {bed_field.es_code => 5, phone_field.es_code => user_2.phone_number, email_field.es_code => user_3.email}
          site1.save!
        end
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([user_2.phone_number], threshold.message_notification, 'smart', collection.id).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([user_3.email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end
      
      describe "send email and sms to all selected fields, members and users" do
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {members: [user.id], fields: [email_field.es_code], users: [user_field.es_code]}, phone_notification: { members: [user.id], fields: [phone_field.es_code], users: [user_field.es_code]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
        before(:each) do
          ResqueSpec.reset!
          site1.properties = {bed_field.es_code => 5, phone_field.es_code => user_2.phone_number, email_field.es_code => user_2.email, user_field.es_code => user_3.email}
          site1.save!
        end
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([user.phone_number, user_2.phone_number, user_3.phone_number], threshold.message_notification, 'smart', collection.id).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([user.email, user_2.email, user_3.email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end
    end
  end
end
