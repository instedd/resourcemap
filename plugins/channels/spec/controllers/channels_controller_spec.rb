require 'spec_helper'

describe ChannelsController do
  include Devise::TestHelpers
  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:channel) { Channel.create(name: 'Mobitel') }
  before(:each) { sign_in user }


  describe 'get reminders' do
    it 'should get channels' do
      get :index, :collection_id => collection.id
      assert_response :success
    end
  end
  
  it 'should create one new channel' do
    expect { 
      post :create, collection_id: collection.id, channel: { name: 'Mobitel', is_share: 'true', is_enable: 'true', collection_id: collection.id, is_manual_configuration: 'true', nuntium_channel_name: 'ch_02' } 
    }.to change { Channel.count }.by 1 
  end

  it 'should update chanel' do
    put :update, collection_id: collection.id, id: channel.id, channel: { name: 'AT&T'}
    Channel.find(channel).name.should == 'AT&T' 
  end
end
