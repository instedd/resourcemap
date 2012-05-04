require 'spec_helper'

describe Collection do
  it { should validate_presence_of :name }
  it { should have_many :memberships }
  it { should have_many :users }
  it { should have_many :layers }
  it { should have_many :fields }
  it { should have_many :thresholds }

  let(:collection) { Collection.make }

  context "max value" do
    it "gets max value for property that exists" do
      collection.sites.make :properties => {'beds' => 10}
      collection.sites.make :properties => {'beds' => 20}, :lat => nil, :lng => nil
      collection.sites.make :properties => {'beds' => 5}

      collection.max_value_of_property('beds').should eq(20)
    end

    it "gets max value for property that doesn't exist" do
      collection.max_value_of_property('beds').should eq(0)
    end
  end

  describe "thresholds test" do
    let!(:collection) { Collection.make }
    let!(:properties) { { 'beds' => 9 } }

    it "should return false when there is no threshold" do
      collection.thresholds_test(properties).should be_false
    end

    it "should return false when no threshold is hit" do
      collection.thresholds.make conditions: [ field: 'beds', is: :gt, value: 10 ]
      collection.thresholds_test(properties).should be_false
    end

    it "should return true when threshold 1 is hit" do
      collection.thresholds.make conditions: [ field: 'beds', is: :lt, value: 10 ]
      collection.thresholds_test(properties).should be_true
    end

    it "should return true when threshold 2 is hit" do
      collection.thresholds.make conditions: [ field: 'beds', is: :gt, value: 10 ]
      collection.thresholds.make conditions: [ field: 'beds', is: :eq, value: 9 ]
      collection.thresholds_test(properties).should be_true
    end
  end
end
