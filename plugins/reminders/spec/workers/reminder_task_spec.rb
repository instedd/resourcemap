require 'spec_helper'
describe ReminderTask do
  let!(:users) { [User.make(:email => 'user@instedd.org', :password => '1234567', :phone_number => '855123456789'), User.make(:email => 'demo@instedd.org', :password => '1234567', :phone_number => '855123333444')]}
  let!(:collection) { Collection.make }
  let!(:layer) { collection.layers.make }
  let!(:phone_field) { layer.phone_fields.make :code => 'phone' } 
  let!(:email_field) { layer.email_fields.make :code => 'email'} 
  
  let!(:site) { collection.sites.make :properties => {phone_field.es_code => users[0].phone_number, email_field.es_code => users[0].email}} 
 
  it 'should include site owner phone_number' do
    ReminderTask.get_site_properties_value_by_kind(site, 'phone').should include(users[0].phone_number)
  end

  it 'should not include other user phone_number' do
  ReminderTask.get_site_properties_value_by_kind(site, 'phone').should_not include(users[1].phone_number)
  end

  it 'should include site owner email' do
    ReminderTask.get_site_properties_value_by_kind(site, 'email').should include(users[0].email)
  end

  it 'should not include other user email' do
    ReminderTask.get_site_properties_value_by_kind(site, 'email').should_not include(users[1].email)
  end

  it 'should return array of phone_number of site_owner' do 
    ReminderTask.get_site_properties_value_by_kind(site, 'phone').should eq [users[0].phone_number]
  end

  it 'should return array of email of site_owner' do
    ReminderTask.get_site_properties_value_by_kind(site, 'email').should eq [users[0].email]
  end
end
