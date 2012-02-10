require 'spec_helper'

describe Site::GeomConcern do
  let(:collection) { Collection.make }

  context "bounds" do
    it "stores bounding box for non-group" do
      site = collection.sites.make
      assert_in_bounds site, site.lat, site.lat, site.lng, site.lng
    end

    it "doesn't store bounding box for group" do
      group = collection.sites.make :group => true
      assert_in_bounds group, nil, nil, nil, nil
    end

    it "modifies bounding box when one child is added" do
      group = collection.sites.make :group => true
      site = collection.sites.make :parent_id => group.id, :lat => 30, :lng => 20

      assert_in_bounds group, site.lat, site.lat, site.lng, site.lng
    end

    it "modifies bounding box when two children are added" do
      group = collection.sites.make :group => true
      site1 = collection.sites.make :parent_id => group.id, :lat => 30, :lng => 20
      site2 = collection.sites.make :parent_id => group.id, :lat => 35, :lng => 15

      assert_in_bounds group, 30, 35, 15, 20
    end

    it "modifies bounding box when two children are added and then one moved" do
      group = collection.sites.make :group => true
      site1 = collection.sites.make :parent_id => group.id, :lat => 30, :lng => 20
      site2 = collection.sites.make :parent_id => group.id, :lat => 35, :lng => 15

      site2.lat = 10
      site2.lng = 25
      site2.save!

      assert_in_bounds group, 10, 30, 20, 25
    end

    it "computes bounding box recurisvely" do
      group1 = collection.sites.make :group => true
      group2 = collection.sites.make :parent_id => group1.id, :group => true
      site11 = collection.sites.make :parent_id => group2.id, :lat => 30, :lng => 20

      assert_in_bounds group2, 30, 30, 20, 20
      assert_in_bounds group1, 30, 30, 20, 20
    end

    it "when changing a group lat/lng doesn't change bounding box" do
      group1 = collection.sites.make :group => true
      group2 = collection.sites.make :parent_id => group1.id, :group => true, :lat => 1, :lng => 2
      site11 = collection.sites.make :parent_id => group2.id, :lat => 30, :lng => 20

      group2.lat = 2
      group2.lng = 3
      group2.save!

      assert_in_bounds group2, 30, 30, 20, 20
      assert_in_bounds group1, 30, 30, 20, 20
    end

    def assert_in_bounds(site, min_lat, max_lat, min_lng, max_lng)
      site.reload
      site.min_lat.to_f.should eq(min_lat.to_f)
      site.max_lat.to_f.should eq(max_lat.to_f)
      site.min_lng.to_f.should eq(min_lng.to_f)
      site.max_lng.to_f.should eq(max_lng.to_f)
    end
  end

  context "zoom" do
    it "stores bounding box for group with one site" do
      site1 = collection.sites.make :group => true
      site2 = collection.sites.make :parent_id => site1.id, :lat => 30, :lng => 40

      assert_in_zoom site1, 22, 22
    end

    it "stores bounding box for group with two sites" do
      site1 = collection.sites.make :group => true
      site2 = collection.sites.make :parent_id => site1.id, :lat => 30, :lng => 40
      site3 = collection.sites.make :parent_id => site1.id, :lat => 40, :lng => 60

      assert_in_zoom site1, 0, 3
    end

    it "stores bounding box for group with subgroups sites" do
      site1 = collection.sites.make :group => true
        site2 = collection.sites.make :group => true, :parent_id => site1.id
          site21 = collection.sites.make :parent_id => site2.id, :lat => 30, :lng => 40
          site22 = collection.sites.make :parent_id => site2.id, :lat => 40, :lng => 60

      assert_in_zoom site1, 0, 3
      assert_in_zoom site2, 4, 3
    end

    it "stores bounding box for group with many subgroups sites" do
      site1 = collection.sites.make :group => true
        site2 = collection.sites.make :group => true, :parent_id => site1.id
          site21 = collection.sites.make :parent_id => site2.id, :lat => 30, :lng => 40
          site21 = collection.sites.make :parent_id => site2.id, :lat => 40, :lng => 60
        site3 = collection.sites.make :group => true, :parent_id => site1.id
          site31 = collection.sites.make :parent_id => site3.id, :lat => 10, :lng => 20
          site32 = collection.sites.make :parent_id => site3.id, :lat => 15, :lng => 20

      assert_in_zoom site1, 0, 2
      assert_in_zoom site2, 3, 3
      assert_in_zoom site3, 3, 5
    end

    def assert_in_zoom(site, min_zoom, max_zoom)
      site.reload
      site.min_zoom.should eq(min_zoom)
      site.max_zoom.should eq(max_zoom)
    end
  end
end
