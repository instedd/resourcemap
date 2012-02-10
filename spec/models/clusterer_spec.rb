require 'spec_helper'

describe Clusterer do
  let(:clusterer) { Clusterer.new 1 }

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
