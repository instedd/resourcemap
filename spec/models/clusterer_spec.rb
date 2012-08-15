require 'spec_helper'

describe Clusterer do
  let(:clusterer) { Clusterer.new 1 }

  it "leaves single site alone" do
    clusterer.add id: 1, name: 'foo',lat: 30, lng: 40, collection_id: 12
    clusters = clusterer.clusters
    clusters[:sites].should eq([{id: 1, name: 'foo', lat: 30, lng: 40, collection_id: 12, highlighted: false}])
    clusters[:clusters].should be_nil
  end

  it "puts two sites in a cluster" do
    clusterer.add :id => 1, :lat => 20, :lng => 30
    clusterer.add :id => 2, :lat => 21, :lng => 31

    clusters = clusterer.clusters
    clusters[:sites].should be_nil
    clusters[:clusters].should eq([{:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 0, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted=>false}])
  end

  it "puts four sites in two different clusters" do
    clusterer.add :id => 1, :lat => 20, :lng => 30
    clusterer.add :id => 2, :lat => 21, :lng => 31
    clusterer.add :id => 3, :lat => 65, :lng => 120
    clusterer.add :id => 4, :lat => 66, :lng => 121

    clusters = clusterer.clusters
    clusters[:sites].should be_nil
    clusters[:clusters].should eq([
      {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 0, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted=>false},
      {:id => "1:3:4", :lat => 65.5, :lng => 120.5, :count => 2, :alert_count => 0, :min_lat => 65, :max_lat => 66, :min_lng => 120, :max_lng => 121, :highlighted=>false}
    ])
  end

  it "puts four sites in two different clusters with two sites alert" do
    clusterer.add :id => 1, :lat => 20, :lng => 30, :alert => "true"
    clusterer.add :id => 2, :lat => 21, :lng => 31
    clusterer.add :id => 3, :lat => 65, :lng => 120, :alert => "true"
    clusterer.add :id => 4, :lat => 66, :lng => 121

    clusters = clusterer.clusters
    clusters[:sites].should be_nil
    clusters[:clusters].should eq([
      {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 1, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted=>false},
      {:id => "1:3:4", :lat => 65.5, :lng => 120.5, :count => 2, :alert_count => 1, :min_lat => 65, :max_lat => 66, :min_lng => 120, :max_lng => 121, :highlighted=>false}
    ])
  end

  it "cluster is highlighted when it contains sites under certain hierarchy" do
     clusterer.highlight(code: "beds", selected: ["2"])
     clusterer.add :id => 1, :lat => 20, :lng => 30, :property => ["2"]
     clusterer.add :id => 2, :lat => 21, :lng => 31, :property => ["1"]

     clusters = clusterer.clusters
     clusters[:sites].should be_nil
     clusters[:clusters].should eq([
       {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 0, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted => true}
     ])
   end

   it "should not highlight cluster when it not contains sites under certain hierarchy" do
      clusterer.highlight(code: "beds", selected: ["2"])
      clusterer.add :id => 1, :lat => 20, :lng => 30, :property => ["7"]
      clusterer.add :id => 2, :lat => 21, :lng => 31, :property => ["1"]

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should eq([
        {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 0, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted => false}
      ])
    end

    it "should highlight cluster when property is multi valued" do
      clusterer.highlight(code: "beds", selected: ["2"])
      clusterer.add :id => 1, :lat => 20, :lng => 30, :property => ["7", "2"]
      clusterer.add :id => 2, :lat => 21, :lng => 31, :property => ["1", "4", "3"]
      clusterer.add :id => 3, :lat => 34, :lng => 0, :property => ["1", "2", "3"]

      clusters = clusterer.clusters

      clusters[:sites].should eq([{:id => 3, :lat => 34, :lng => 0, :highlighted => true}])
      clusters[:clusters].should eq([
        {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 0, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted => true}
      ])
    end

    it "should select more than one value (for hiearchies >1 level)" do
      clusterer.highlight(code: "beds", selected: ["2", "3"])
      clusterer.add :id => 1, :lat => 20, :lng => 30, :property => ["7", "2"]
      clusterer.add :id => 2, :lat => 21, :lng => 31, :property => ["1", "4", "3"]
      clusterer.add :id => 3, :lat => 34, :lng => 0, :property => ["1", "2", "3"]

      clusters = clusterer.clusters

      clusters[:sites].should eq([{:id => 3, :lat => 34, :lng => 0, :highlighted => true}])
      clusters[:clusters].should eq([
        {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 0, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted => true}
      ])
    end


end
