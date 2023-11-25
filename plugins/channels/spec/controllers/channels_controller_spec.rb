require 'spec_helper'

describe ChannelsController, :type => :controller do
  skip do
    include Devise::TestHelpers
    let(:user) { User.make }
    let(:collection) { user.create_collection(Collection.make_unsaved) }
    let(:channel) { Channel.create(name: 'Mobitel', ticket_code: 'abcd') }
    before(:each) { sign_in user }


    describe 'get reminders', :type => :controller do
      it 'should get channels' do
        get :index, params: { :collection_id => collection.id }
        assert_response :success
      end
    end

    it 'should create one new channel' do
      expect {
        post :create, params: { collection_id: collection.id, channel: {"collection_id"=>collection.id, "name"=>"Mobitel1", "password"=>"12345"} }
      }.to change { Channel.count }.by 1
    end

    it 'should update channel' do
      put :update, params: { collection_id: collection.id, id: channel.id, channel: { name: 'AT&T'} }
      Channel.find(channel).name.should == 'AT&T'
    end

    it 'should delete channel' do
      expect{
        delete :destroy, params: { collection_id: collection.id, id: channel.id }
      }.to change { Channel.count }.by -1
    end

    it 'should update status' do
      channel.collections = [collection]
      post :set_status, params: { :id => channel.id, :collection_id => collection.id, :status => true }
      ShareChannel.where(:channel_id => channel.id, :collection_id => collection.id).first.status.should == true
    end
  end
end
