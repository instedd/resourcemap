require 'spec_helper'

describe Site::AlertConcerns do 
  let!(:collection) { Collection.make :plugins => {"alerts" => {}} }
  let!(:layer) { collection.layers.make }
  let!(:bed_field) { layer.fields.make :code => 'bed' }
  let!(:phone_field) { layer.fields.make :code => 'phone' } 
  let!(:email_field) { layer.fields.make :code => 'email' } 
  let!(:user_field) { layer.fields.make :code => 'user' } 
  
  describe "adding queue when hit alert threshold" do 
    let!(:users) { [User.make(:email => 'user@instedd.org', :password => '1234567', :phone_number => '855123456789')]}
    let!(:site1) { collection.sites.make :properties => {bed_field.es_code => 15, phone_field.es_code => users[0].phone_number, email_field.es_code => users[0].email, user_field.es_code => users[0].email}}
    let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {users: [user_field.es_code], fields: [email_field.es_code], members: [users[0].id]}, phone_notification: {users: [user_field.es_code], fields: [phone_field.es_code], members: [users[0].id]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
    let!(:message_notification) { "alert sms"} 
     
    describe "add new site" do
      let!(:site) {collection.sites.make :properties => {bed_field.es_code => 5, phone_field.es_code => users[0].phone_number, email_field.es_code => users[0].email, user_field.es_code => users[0].email}}
      it "should add sms_que into Resque.enqueue with users and message_notification" do 
        SmsTask.should have_queued([users[0].phone_number, users[0].phone_number, users[0].phone_number], message_notification).in(:sms_queue)
      end

      it "should add email_que into Resque.enqueue with threshold and message_notification" do 
        EmailTask.should have_queued([users[0].email, users[0].email, users[0].email], message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
      end
    end

    describe "edit site" do
      it "should add sms_que into Resque.enqueue with users and message_notification" do 
        site1.properties = {bed_field.es_code => 5, phone_field.es_code => [], email_field.es_code => users[0].email, user_field.es_code => users[0].email}
        site1.save 
        SmsTask.should have_queued([users[0].phone_number, users[0].phone_number], message_notification).in(:sms_queue)
      end

      it "should add email_que into Resque.enqueue with threshold and message_notification" do 
        site1.properties = {bed_field.es_code => 5, user_field.es_code => users[0].email}
        site1.save 
        EmailTask.should have_queued([users[0].email, users[0].email], message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
      end
    end
  end

end
