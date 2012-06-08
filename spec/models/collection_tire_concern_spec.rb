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

  it "create proper index name" do
    index_name = Collection.index_name 32
    index_name.should eq("collection_test_32")

    index_name_for_snapshot = Collection.index_name 32, snapshot: "last_year"
    index_name_for_snapshot.should eq("collection_test_32_last_year")
  end
  
  
end
