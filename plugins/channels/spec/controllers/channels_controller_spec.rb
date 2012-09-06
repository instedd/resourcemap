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
      post :create, collection_id: collection.id, channel: {"collection_id"=>collection.id, "name"=>"Mobitel1", "is_share"=>"false", "is_manual_configuration"=>"true", "password"=>"12345"}  
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
    channel.collections = [collection]
    post :set_status, :id => channel.id, :collection_id => collection.id, :status => true
    ShareChannel.where(:channel_id => channel.id, :collection_id => collection.id).first.status.should == true
  end

end
