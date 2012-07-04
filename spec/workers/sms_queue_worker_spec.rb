require 'spec_helper'
describe SmsQueue do
  describe '#perform' do
    let!(:users){[User.create(:email => 'user@instedd.org', :password => '12345', :phone_number => '855123456789')]} 
    pending 'should call perform' do 
    end
  end
end

