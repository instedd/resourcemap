require 'spec_helper'

describe RemindersController do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }

  before(:each) { sign_in user }
  
  describe 'get reminders' do
    it 'should get reminders' do
      get :index
      assert_response :success
    end
  end
  
  describe 'create reminder' do
    before(:each) do
      @site = collection.sites.make
    end
    
    it "should create reminder" do
      Reminder.count.should == 0
      post :create, :reminder => {"name"=>"foo", "reminder_date"=>"2012-05-06T00:30:00Z 0:00", "reminder_message"=>"foo", "repeat_id"=>"1", "collection_id"=>"1", "sites"=>[@site.id]}
      Reminder.count.should == 1
      assert_response :success
    end
  end
  
  describe 'update reminder' do
    before(:each) do
      @site = collection.sites.make
      @reminder = collection.reminders.make
    end
    
    it "should update reminder" do
      put :update, :id => @reminder.id, :collection_id => collection.id, :reminder => {"name"=>"foo", "reminder_date"=>"2012-05-06T00:30:00Z 0:00", "reminder_message"=>"foo", "repeat_id"=>"1", "collection_id"=>collection.id, "sites"=>[@site.id]}
      assert_response :success
    end
    
  end
  
  describe 'destroy reminder' do
    before(:each) do
      @reminder = collection.reminders.make
    end
    
    it "should destroy reminder" do
      Reminder.count.should == 1
      delete :destroy, :id => @reminder.id, :collection_id => collection.id
      Reminder.count.should == 0
      assert_response :success
    end
  end
  
end
