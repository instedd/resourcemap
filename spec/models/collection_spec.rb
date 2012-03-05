require 'spec_helper'

describe Collection do
  it { should validate_presence_of :name }
  it { should have_many :memberships }
  it { should have_many :users }
  it { should have_many :layers }
  it { should have_many :fields }

  let(:collection) { Collection.make }

  context "max value" do
    it "gets max value for property that exists" do
      collection.sites.make :properties => {'beds' => 10}
      collection.sites.make :properties => {'beds' => 20}
      collection.sites.make :properties => {'beds' => 5}

      collection.max_value_of_property('beds').should eq(20)
    end

    it "gets max value for property that doesn't exist" do
      collection.max_value_of_property('beds').should eq(0)
    end
  end
end
