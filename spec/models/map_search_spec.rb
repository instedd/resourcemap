require 'spec_helper'

describe MapSearch, :type => :model do
  let(:collection) { Collection.make }

  it "searches based on no collection" do
    site = Site.make

    search = MapSearch.new []
    search.zoom = 1
    expect(search.results).to eq({})
  end

  it "searches based on collection id found" do
    site = Site.make

    search = MapSearch.new site.collection_id
    search.zoom = 1

    expect(search.results[:sites].length).to be(1)
    expected_hash = {collection_id: site.collection_id, id: site.id,
    lat: site.lat.to_f, lng: site.lng.to_f,
    name: site.name, id_with_prefix:"AA1",
    lat_analyzed: site.lat.to_s, lng_analyzed: site.lng.to_s,
    uuid: site.uuid, highlighted: false, icon: 'default', alert: 'false', version: '1'}
    expect(search.results[:sites][0]).to eq(expected_hash)
  end

  it "searches with excluded id" do
    site = Site.make

    search = MapSearch.new site.collection_id
    search.zoom = 1
    search.exclude_id site.id
    expect(search.results[:sites]).to be_nil
  end

  it "searches based on collection id not found" do
    site = Site.make
    other_collection = Collection.make

    search = MapSearch.new other_collection.id
    search.zoom = 1
    expect(search.results[:sites]).to be_nil
  end

  it "searches based on many collection ids found" do
    site1 = Site.make :lat => 45, :lng => 90
    site2 = Site.make :lat => -45, :lng => -90

    search = MapSearch.new [site1.collection_id, site2.collection_id]
    search.zoom = 1
    expect(search.results[:sites].length).to eq(2)
  end

  it "searches based on collection id and bounds found" do
    site = Site.make :lat => 10, :lng => 20

    search = MapSearch.new site.collection_id
    search.zoom = 10
    search.bounds = {:s => 9, :n => 11, :w => 19, :e => 21}
    expect(search.results[:sites].length).to eq(1)
  end

  it "searches based on collection id and bounds not found" do
    site = Site.make :lat => 10, :lng => 20

    search = MapSearch.new site.collection_id
    search.zoom = 10
    search.bounds = {:s => 11, :n => 12, :w => 21, :e => 22}
    expect(search.results[:sites]).to be_nil
  end

  it "searches but doesn't return sites without location" do
    site = Site.make :lat => nil, :lng => nil

    search = MapSearch.new site.collection_id
    search.zoom = 1
    search.bounds = {:s => 11, :n => 12, :w => 21, :e => 22}
    expect(search.results[:sites]).to be_nil
  end

  context "full text search" do
    let!(:layer) { collection.layers.make }
    let!(:field_prop) { layer.select_one_fields.make :code => 'prop', :config => {'options' => [{'id' => 1, 'code' => 'foo', 'label' => 'A glass of water'}, {'id' => 2, 'code' => 'bar', 'label' => 'A bottle of wine'}, {'id' => 3, 'code' => 'baz', 'label' => 'COCO'}]} }
    let!(:field_beds) { layer.numeric_fields.make  :code => 'beds' }
    let!(:prop) { field_prop.es_code }
    let!(:beds) { field_beds.es_code }
    let!(:site1) { collection.sites.make :name => "Argentina", :properties => {beds => 8, prop => 1} }
    let!(:site2) { collection.sites.make :name => "Buenos Aires", :properties => {beds => 10, prop => 2} }
    let!(:site3) { collection.sites.make :name => "Cordoba bar", :properties => {beds => 20, prop => 3} }
    let!(:search) { MapSearch.new collection.id }

    before(:each) { search.zoom = 1 }

    it "searches by name" do
      search.full_text_search 'Argent'
      assert_result search, site1
    end

    it "searches by number property" do
      search.full_text_search '8'
      assert_result search, site1
    end

    it "searches by text property" do
      search.full_text_search 'foo'
      assert_result search, site1
    end

    it "searches by select one property" do
      search.full_text_search 'water'
      assert_result search, site1
    end

    it "doesn't give false positives" do
      search.full_text_search 'wine'
      assert_result search, site2
    end

    skip "searches by name property" do
      search.full_text_search('name:"Buenos Aires"')
      assert_result search, site2
    end

    it "searches by numeric property" do
      search.full_text_search('beds:8')
      assert_result search, site1
    end

    it "searches by numeric property with comparison" do
      search.full_text_search('beds:>10')
      assert_result search, site3
    end

    def assert_result(search, site)
      results = search.results
      expect(results[:sites].length).to eq(1)
      expect(results[:sites][0][:id]).to eq(site.id)
    end
  end
end
