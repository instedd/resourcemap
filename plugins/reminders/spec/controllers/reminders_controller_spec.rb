require 'spec_helper'

describe RemindersController, :type => :controller do
  include Devise::TestHelpers

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:site) { collection.sites.make }
  let!(:repeat) { repeat = Repeat.make }
  let!(:reminder) { collection.reminders.make }

  before(:each) { sign_in user }

  describe 'get reminders' do
    it 'should get reminders' do
      get :index, :collection_id => collection.id
      assert_response :success
    end
  end

  it "should create reminder" do
    expect {
      post :create, collection_id: collection.id, reminder: { name: "foo", reminder_date: "2012-05-06T00:30:00Z 0:00", reminder_message: "foo", repeat_id: repeat.id, collection_id: 1, sites: [site.id] }
    }.to change { Reminder.count }.by 1
  end

  it "should update reminder" do
    put :update, :id => reminder.id, :collection_id => collection.id, :reminder => { name: "foo" }
    expect(reminder.reload.name).to eq("foo")
  end

  it "should destroy reminder" do
    expect {
      delete :destroy, :id => reminder.id, :collection_id => collection.id
    }.to change { Reminder.count }.by -1
  end

  it 'should update status' do
    post :set_status, :id => reminder.id, :collection_id => collection.id, :status => true
    expect(reminder.reload.status).to eq(true)
  end

  it "should not create reminder for guest" do
    sign_out user
    expect {
      post :create, collection_id: collection.id, reminder: { name: "foo", reminder_date: "2012-05-06T00:30:00Z 0:00", reminder_message: "foo", repeat_id: repeat.id, collection_id: 1, sites: [site.id] }
    }.to change { Reminder.count }.by 0
  end

  context 'non members' do
    before(:each) do
      sign_out user
      non_member = User.make
      sign_in non_member
    end

    it "should not create reminder" do
      expect {
        post :create, collection_id: collection.id, reminder: { name: "foo", reminder_date: "2012-05-06T00:30:00Z 0:00", reminder_message: "foo", repeat_id: repeat.id, collection_id: 1, sites: [site.id] }
      }.to change { Reminder.count }.by 0
    end

    it "should not update reminder" do
      reminder.name = "old"
      reminder.save!
      put :update, :id => reminder.id, :collection_id => collection.id, :reminder => { name: "foo" }
      expect(reminder.reload.name).to eq("old")
    end

    it "should not destroy reminder" do
      expect {
        delete :destroy, :id => reminder.id, :collection_id => collection.id
      }.to change { Reminder.count }.by 0
    end

    it 'should not update status' do
      post :set_status, :id => reminder.id, :collection_id => collection.id, :status => true
      expect(reminder.reload.status).to eq(nil)
    end
  end
end
