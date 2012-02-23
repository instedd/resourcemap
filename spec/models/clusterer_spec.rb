require 'spec_helper'

describe Clusterer do
  let(:clusterer) { Clusterer.new 1 }

  context "no groups" do
    it "leaves single site alone" do
      clusterer.add :id => 1, :lat => 30, :lng => 40
      clusters = clusterer.clusters
      clusters[:sites].should eq([{:id => 1, :lat => 30, :lng => 40}])
      clusters[:clusters].should be_nil
    end

    it "puts two sites in a cluster" do
      clusterer.add :id => 1, :lat => 20, :lng => 30
      clusterer.add :id => 2, :lat => 21, :lng => 31

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should eq([{:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2}])
    end

    it "puts four sites in two different clusters" do
      clusterer.add :id => 1, :lat => 20, :lng => 30
      clusterer.add :id => 2, :lat => 21, :lng => 31
      clusterer.add :id => 3, :lat => 65, :lng => 120
      clusterer.add :id => 4, :lat => 66, :lng => 121

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should eq([{:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2}, {:id => "1:3:4", :lat => 65.5, :lng => 120.5, :count => 2}])
    end
  end

  context "with groups" do
    before(:each) { clusterer.groups = [{:id => 1, :lat => 2, :lng => 3}, {:id => 2, :lat => 4, :lng => 5}] }

    it "clusters inside group" do
      clusterer.add :id => 1, :lat => 20, :lng => 30, :parent_ids => [4, 5, 1]
      clusterer.add :id => 2, :lat => 20, :lng => 30, :parent_ids => [6, 1, 7]

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should eq([{:id => "g1", :lat => 2, :lng => 3, :count => 2}])
    end

    it "clusters groups if they are too near" do
      clusterer.add :id => 1, :lat => 20, :lng => 30, :parent_ids => [4, 5, 1]
      clusterer.add :id => 2, :lat => 20, :lng => 30, :parent_ids => [6, 1, 7]

      clusterer.add :id => 3, :lat => 20, :lng => 30, :parent_ids => [2]
      clusterer.add :id => 4, :lat => 20, :lng => 30, :parent_ids => [2]

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should eq([{:id => "1:1:3", :lat => 3.0, :lng => 4.0, :count => 4}])
    end

    it "clusters groups and non-groups" do
      clusterer.add :id => 1, :lat => 20, :lng => 30, :parent_ids => [4, 5, 1]
      clusterer.add :id => 2, :lat => 20, :lng => 30, :parent_ids => [6, 1, 7]

      clusterer.add :id => 3, :lat => 4, :lng => 5, :parent_ids => []
      clusterer.add :id => 4, :lat => 4, :lng => 5, :parent_ids => []

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should eq([{:id => "1:1:3", :lat => 3.0, :lng => 4.0, :count => 4}])
    end

    it "clusters groups if they are too near, and a site" do
      clusterer.add :id => 1, :lat => 20, :lng => 30, :parent_ids => [4, 5, 1]
      clusterer.add :id => 2, :lat => 20, :lng => 30, :parent_ids => [6, 1, 7]

      clusterer.add :id => 3, :lat => 20, :lng => 30, :parent_ids => [2]
      clusterer.add :id => 4, :lat => 20, :lng => 30, :parent_ids => [2]

      clusterer.add :id => 5, :lat => 3.0, :lng => 4.0, :parent_ids => []

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should eq([{:id => "1:1:3", :lat => 3.0, :lng => 4.0, :count => 5}])
    end
  end
end
