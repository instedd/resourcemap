require 'spec_helper'

describe Clusterer do
  let(:clusterer) { Clusterer.new 2 }

  it "leaves single site alone" do
    site = {:id => 1, :lat => 30, :lng => 40}
    clusterer.add site
    clusters = clusterer.clusters
    clusters[:sites].should eq([site])
    clusters[:clusters].should be_empty
  end

  it "puts two sites in a cluster" do
    clusterer.add :id => 1, :lat => 30, :lng => 20
    clusterer.add :id => 2, :lat => 40, :lng => 30

    clusters = clusterer.clusters
    clusters[:sites].should be_empty
    clusters[:clusters].should eq([{:id => "2:2:2", :lat => 35, :lng => 25, :count => 2}])
  end

  it "puts four sites in two different clusters" do
    clusterer.add :id => 1, :lat => 30, :lng => 20
    clusterer.add :id => 2, :lat => 40, :lng => 30
    clusterer.add :id => 3, :lat => 120, :lng => 65
    clusterer.add :id => 4, :lat => 130, :lng => 75

    clusters = clusterer.clusters
    clusters[:sites].should be_empty
    clusters[:clusters].should =~ [{:id => "2:2:2", :lat => 35, :lng => 25, :count => 2}, {:id => "2:3:3", :lat => 125, :lng => 70, :count => 2}]
  end
end
