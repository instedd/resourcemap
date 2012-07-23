require 'spec_helper'

describe Site::AlertConcerns do 
  let!(:collection) { Collection.make }
  let!(:layer) { collection.layers.make }
  let!(:beds_field) { layer.fields.make :code => 'beds' }
  let!(:tables_field) { layer.fields.make :code => 'tables' }

  describe "adding queue when hit alert threshold" do 
    let!(:users) { [User.make(:email => 'user@instedd.org', :password => '1234567', :phone_number => '855123456789')]}
    let!(:site1) { collection.sites.make :properties => {beds_field.es_code => 15, users[0].id => "", users[0].id => ""}}
    let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {users: [users[0].id], fields: [users[0].id], members: [users[0].id]}, phone_notification: {users: [users[0].id], fields: [users[0].id], members: [users[0].id]}, message_notification: "alert sms", conditions: [ field: beds_field.es_code, op: :lt, value: 10 ]}
    let!(:message_notification) { "alert sms"} 
     
    describe "add new site" do
      let!(:site) {collection.sites.make :properties => {beds_field.es_code => 5}}
      it "should add sms_que into Resque.enqueue with users and message_notification" do 
        SmsTask.should have_queued([users[0].phone_number], message_notification).in(:sms_queue)
      end

      it "should add email_que into Resque.enqueue with threshold and message_notification" do 
        EmailTask.should have_queued([users[0].email], message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
      end
    end

    describe "edit site" do
      it "should add sms_que into Resque.enqueue with users and message_notification" do 
        site1.properties = {beds_field.es_code => 5}
        site1.save 
        SmsTask.should have_queued([users[0].phone_number], message_notification).in(:sms_queue)
      end

      it "should add email_que into Resque.enqueue with threshold and message_notification" do 
        site1.properties = {beds_field.es_code => 5}
        site1.save 
        EmailTask.should have_queued([users[0].email], message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
      end
    end
  end

end
