require 'spec_helper'

describe Collection do
  it { should validate_presence_of :name }
  it { should have_many :memberships }
  it { should have_many :users }
  it { should have_many :layers }
  it { should have_many :fields }

  context "tire" do
    let(:collection) { Collection.make }

    it "creates index on create" do
      Tire::Index.new(collection.index_name).exists?.should be_true
    end

    it "destroys index on destroy" do
      collection.destroy
      Tire::Index.new(collection.index_name).exists?.should be_false
    end
  end
end
