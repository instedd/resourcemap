require 'spec_helper'

describe ThresholdsController, :type => :controller do
  include Devise::TestHelpers

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make_unsaved) }
  let(:site) { Site.make }
  before(:each) { sign_in user }

  let(:condition_attributes) { {"field"=>"392", "op"=>"eq", "value"=>"20", "type"=>"value"} }
  let(:sites) { {"id" => site.id, "name" => "SR Health Center"} }
  let(:threshold) { collection.thresholds.make }

  describe 'Create threshold' do
    it 'should fix conditions' do
      post :create, "threshold"=>{"color"=>"red", "ord" => 1, "sites" => {"0" => sites}, "conditions"=>{"0"=>condition_attributes}}, "collection_id" => collection.id

      threshold = collection.thresholds.last
      expect(threshold.conditions.size).to eq(1)
      expect(threshold.conditions[0]).to eq condition_attributes
    end
  end

  describe 'Update threshold' do
    it 'should fix conditions' do

      put :update, "threshold"=>{ "conditions"=>{"0"=>condition_attributes}, "sites" => {"0" => sites}}, "collection_id" => collection.id, "id" => threshold.id

      threshold.reload
      expect(threshold.conditions[0]).to eq condition_attributes
    end
  end

  it "should create threshold" do
    expect {
      post :create, "threshold"=>{"color"=>"red", "ord" => 1, "sites" => {"0" => sites}, "conditions"=>{"0"=>condition_attributes}}, "collection_id" => collection.id
    }.to change { Threshold.count }.by 1
  end

  it "should update threshold" do
    put :update, id: threshold.id, collection_id: collection.id, threshold: {ord: 2, "conditions"=>{"0"=>condition_attributes}, "sites" => {"0" => sites}}
    expect(Threshold.find(threshold.id).ord).to eq(2)
  end

  it "should destroy threshold" do
    threshold
    expect {
      delete :destroy, :collection_id => collection.id, :id => threshold.id
    }.to change { Threshold.count }.by -1
  end

  it "should not create threshold for guest" do
    sign_out user
    expect {
      post :create, threshold: { conditions: {"0"=>condition_attributes}, sites: {"0" => sites}, ord: 1, color: 'red'}, collection_id: collection.id
    }.to change { Threshold.count }.by 0
  end

  context 'non members' do
    before(:each) do
      sign_out user
      non_member = User.make
      sign_in non_member
    end

    it "should not create threshold" do
      expect {
        post :create, threshold: { conditions: {"0"=>condition_attributes}, sites: {"0" => sites}, ord: 1, color: 'red'}, collection_id: collection.id
      }.to change { Threshold.count }.by 0
    end

    it "should not update threshold" do
      threshold.ord = 1
      threshold.save!
      put :update, id: threshold.id, collection_id: collection.id, threshold: {ord: 2, "conditions"=>{"0"=>condition_attributes}, "sites" => {"0" => sites}}
      expect(Threshold.find(threshold.id).ord).to eq(1)
    end

    it "should not destroy threshold" do
      threshold
      expect {
        delete :destroy, :id => threshold.id, :collection_id => collection.id
      }.to change { Threshold.count }.by 0
    end
  end


end
