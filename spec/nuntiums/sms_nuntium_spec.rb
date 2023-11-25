require 'spec_helper'
describe SmsNuntium do
  let(:users){User.create(:email => 'user2@instedd.org', :password => '12345', :phone_number => '855123456789')}
  let(:collection) { Collection.make }
  it 'should send sms to correct user' do
    nuntium = double("Nuntium")
    expect(Nuntium).to receive(:new_from_config).and_return(nuntium)
    expect(nuntium).to receive(:send_ao).with([{:from =>"resourcemap", :to => "sms://855123456789", :body => "alert", :suggested_channel => "testing" }])
    SmsNuntium.notify_sms [users.phone_number], "alert", "testing", collection.id
  end
end
