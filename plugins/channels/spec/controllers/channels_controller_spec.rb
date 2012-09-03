require 'spec_helper'

describe ChannelsController do
  include Devise::TestHelpers
  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:channel) { Channel.create(name: 'Mobitel', collection_id: collection.id, ticket_code: 'abcd') }
  before(:each) { sign_in user }


  describe 'get reminders' do
    it 'should get channels' do
      get :index, :collection_id => collection.id
      assert_response :success
    end
  end
  
  it 'should create one new channel' do
    expect { 
      post :create, collection_id: collection.id, channel: { name: 'Mobitel', is_share: 'true', is_enable: 'true', collection_id: collection.id, is_manual_configuration: 'true', nuntium_channel_name: 'ch_02', share_collections: [1,2] } 
    }.to change { Channel.count }.by 1 
  end

  it 'should update channel' do
    put :update, collection_id: collection.id, id: channel.id, channel: { name: 'AT&T'}
    Channel.find(channel).name.should == 'AT&T' 
  end

  it 'should delete channel' do
    expect{
      delete :destroy, collection_id: collection.id, id: channel.id
    }.to change { Channel.count }.by -1
  end

  it 'should update status' do 
    post :set_status, :id => channel.id, :collection_id => collection.id, :status => true
    Channel.find(channel).status.should == true
  end

end
