require 'spec_helper'

describe Clusterer do
  let(:clusterer) { Clusterer.new 1 }

  context "no groups" do
    it "leaves single site alone" do
      clusterer.add 1, 30, 40
      clusters = clusterer.clusters
      clusters[:sites].should eq([{:id => 1, :lat => 30, :lng => 40}])
      clusters[:clusters].should be_nil
    end

    it "puts two sites in a cluster" do
      clusterer.add 1, 20, 30
      clusterer.add 2, 30, 40

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should eq([{:id => "1:2:4", :lng => 35, :lat => 25, :count => 2}])
    end

    it "puts four sites in two different clusters" do
      clusterer.add 1, 20, 30
      clusterer.add 2, 30, 40
      clusterer.add 3, 65, 120
      clusterer.add 4, 75, 130

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should =~ [{:id => "1:2:4", :lng => 35, :lat => 25, :count => 2}, {:id => "1:4:5", :lng => 125, :lat => 70, :count => 2}]
    end
  end

  context "with groups" do
    before(:each) { clusterer.groups = [{:id => 1, :lat => 2, :lng => 3}, {:id => 2, :lat => 4, :lng => 5}] }

    it "clusters inside group" do
      clusterer.add 1, 20, 30, [4, 5, 1]
      clusterer.add 2, 20, 30, [6, 1, 7]

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should =~ [{:id => "g1", :lat => 2, :lng => 3, :count => 2}]
    end
  end
end
