require 'spec_helper'

describe Clusterer do
  let(:clusterer) { Clusterer.new 1 }
  let(:collection) { Collection.make }
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
    clusters[:clusters].should eq([{:alert => false, :status => true, :icon => "", :color => "", :id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 0, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted=>false}])
  end

  it "puts four sites in two different clusters" do
    clusterer.add :id => 1, :lat => 20, :lng => 30
    clusterer.add :id => 2, :lat => 21, :lng => 31
    clusterer.add :id => 3, :lat => 65, :lng => 120
    clusterer.add :id => 4, :lat => 66, :lng => 121

    clusters = clusterer.clusters
    clusters[:sites].should be_nil
    clusters[:clusters].should eq([
      {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 0, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted=>false, :alert => false, :status => true, :icon => "", :color => "" },
      {:id => "1:3:4", :lat => 65.5, :lng => 120.5, :count => 2, :alert_count => 0, :min_lat => 65, :max_lat => 66, :min_lng => 120, :max_lng => 121, :highlighted=>false, :alert => false, :status => true, :icon => "", :color => "" }
    ])
  end

  it "puts four sites in two different clusters with two sites alert" do
    clusterer.add :id => 1, :lat => 20, :lng => 30, :alert => "true", :collection_id => collection.id
    clusterer.add :id => 2, :lat => 21, :lng => 31
    clusterer.add :id => 3, :lat => 65, :lng => 120, :alert => "true", :collection_id => collection.id
    clusterer.add :id => 4, :lat => 66, :lng => 121

    clusters = clusterer.clusters
    clusters[:sites].should be_nil
    clusters[:clusters].should eq([
      {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 1, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted=>false, :alert => true, :status => false, :icon => "default", :color => ""},
      {:id => "1:3:4", :lat => 65.5, :lng => 120.5, :count => 2, :alert_count => 1, :min_lat => 65, :max_lat => 66, :min_lng => 120, :max_lng => 121, :highlighted=>false, :alert => true, :status => false, :icon => "default", :color => ""}
    ])
  end

  it "cluster is highlighted when it contains sites under certain hierarchy" do
     clusterer.highlight(code: "beds", selected: ["2"])
     clusterer.add :id => 1, :lat => 20, :lng => 30, :property => ["2"]
     clusterer.add :id => 2, :lat => 21, :lng => 31, :property => ["1"]

     clusters = clusterer.clusters
     clusters[:sites].should be_nil
     clusters[:clusters].should eq([
       {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 0, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted => true, :alert => false, :status => true, :icon => "", :color => "" }
     ])
   end

   it "should not highlight cluster when it not contains sites under certain hierarchy" do
      clusterer.highlight(code: "beds", selected: ["2"])
      clusterer.add :id => 1, :lat => 20, :lng => 30, :property => ["7"]
      clusterer.add :id => 2, :lat => 21, :lng => 31, :property => ["1"]

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should eq([
        {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 0, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted => false, :alert => false, :status => true, :icon => "", :color => "" }
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
        {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 0, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted => true, :alert => false, :status => true, :icon => "", :color => "" }
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
        {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 0, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted => true, :alert => false, :status => true, :icon => "", :color => "" }
      ])
    end

    it "should add ghost lat and lng to each site for site in identical location if clustering is not enabled" do
      clusterer.send(:initialize, 21)
      clusterer.add :id => 1, :lat => 20, :lng => 30
      clusterer.add :id => 2, :lat => 20, :lng => 30
      clusterer.add :id => 3, :lat => 20, :lng => 30
      clusterer.add :id => 4, :lat => 20, :lng => 30

      clusters = clusterer.clusters
      clusters[:sites].should eq(
        [{:id=>1, :lat=>20, :lng=>30, :ghost_radius => 2*Math::PI/4 * 0 },
        {:id=>2, :lat=>20, :lng=>30, :ghost_radius => 2*Math::PI/4 * 1 },
        {:id=>3, :lat=>20, :lng=>30, :ghost_radius => 2*Math::PI/4 * 2 },
        {:id=>4, :lat=>20, :lng=>30, :ghost_radius => 2*Math::PI/4 * 3 }
        ])
      clusters[:clusters].should be_nil
      clusters[:original_ghost].should eq([{:lat => 20, :lng => 30}])

    end
  
    it 'should set status = false when two sites in difference collection in the same cluster' do
      clusterer.add :id => 1, :lat => 20, :lng => 30, :alert => "true", :collection_id => collection.id
      clusterer.add :id => 2, :lat => 21, :lng => 31, :collection_id => 1

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should eq([
        {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 1, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted=>false, :alert => true, :status => false, :icon => "default", :color => ""}
      ])
    end
    
    it 'should return status = true, icon = cycling and color = nil  when two sites in difference collection in the same cluster' do
      clusterer.add :id => 1, :lat => 20, :lng => 30, :alert => "true", :collection_id => collection.id, :icon => 'cycling'
      clusterer.add :id => 2, :lat => 21, :lng => 31, :collection_id => collection.id , :icon => 'cycling'

      clusters = clusterer.clusters
      clusters[:sites].should be_nil
      clusters[:clusters].should eq([
        {:id => "1:2:3", :lat => 20.5, :lng => 30.5, :count => 2, :alert_count => 1, :min_lat => 20, :max_lat => 21, :min_lng => 30, :max_lng => 31, :highlighted=>false, :alert => true, :status => true, :icon => "cycling", :color => nil}
      ])
    end

end
