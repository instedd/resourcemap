require 'spec_helper'

describe Site do
  it { should belong_to :collection }
  it { should belong_to :parent }
  its(:group) { should be_false }

  context "hierarchy" do
    it "stores nil hierarchy for root" do
      site = Site.make
      site.hierarchy.should be_nil
    end

    it "stores hierarchy" do
      collection = Collection.make
      site1 = collection.sites.make
      site2 = collection.sites.make :parent_id => site1.id
      site3 = collection.sites.make :parent_id => site2.id

      site1.reload
      site1.hierarchy.should be_nil

      site2.reload
      site2.hierarchy.should eq("#{site1.id}")

      site3.reload
      site3.hierarchy.should eq("#{site1.id},#{site2.id}")
    end
  end

  context "level" do
    it "gets level for groups and sites" do
      collection = Collection.make
      site1 = collection.sites.make
      site2 = collection.sites.make :parent_id => site1.id
      site3 = collection.sites.make :parent_id => site2.id

      site1.level.should eq(1)
      site2.level.should eq(2)
      site3.level.should eq(3)
    end
  end

  it "removes empty properties after save" do
    site = Site.make properties: {foo: 1, bar: nil, baz: 3}
    site.properties.should_not have_key(:bar)
  end
end
