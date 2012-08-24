require 'spec_helper'

describe ChannelsController do
  include Devise::TestHelpers
  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:site) { collection.sites.make }
  let!(:channel) { collection.channels.make }
  before(:each) { sign_in user }

  describe 'get channels' do
    it 'should get channels' do
      get :index, :collection_id => collection.id
      assert_response :success
    end
  end
end
