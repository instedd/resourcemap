require 'spec_helper'

describe Collection::TireConcern do
  let(:collection) { Collection.make }

  it "creates index on create" do
    Tire::Index.new(collection.index_name).exists?.should be_true
  end

  it "destroys index on destroy" do
    collection.destroy
    Tire::Index.new(collection.index_name).exists?.should be_false
  end
end
