require 'spec_helper'

describe QuotasController do
  include Devise::TestHelpers
  render_views

  let(:user) { User.make }
  let(:collection) { Collection.make }
   
  before(:each) { sign_in user }
  it 'should upate message quota on collection from 0 to 10' do 
    expect{
      post :create, collection_id: collection.id, quota: 10, format: 'json'
    }.to change{
      c = Collection.find collection.id
      c.quota
    }.from(0).to(10)
  end

  it 'should respond the collection depend on collection_id' do
    get :show, id: collection.id
    assert_response :success
  end
end
