require 'spec_helper'

describe SiteHistory do
  it { should belong_to :site }

  def assert_properties(site_history, site)
    site_history.site_id.should == site.id
    site_history.collection_id.should == site.collection_id
    site_history.name.should == site.name
    site_history.lat.should == site.lat
    site_history.lng.should == site.lng
    site_history.parent_id.should == site.parent_id
    site_history.hierarchy.should == site.hierarchy
    site_history.properties.should eq(site.properties)
    site_history.location_mode.should == site.location_mode
    site_history.id_with_prefix.should == site.id_with_prefix
  end

  it "should create from site" do
    site = Site.make
    site_history = SiteHistory.create_from_site site
    assert_properties(site_history, site)
    site_history.valid_to.should be_nil
    site_history.valid_since.to_i.should eq(site.created_at.to_i)
  end

  it "should get current value for new site" do
    site = Site.make
    site_history = SiteHistory.get_current_value site
    site_history.should be
    site_history.valid_to.should be_nil
    assert_properties(site_history, site)
    site_history.valid_since.to_i.should eq(site.created_at.to_i)
  end

  it "should get current value for updated site" do
    site = Site.make
    sleep 1
    site.name = "new name"
    site.save
    site_history = SiteHistory.get_current_value site
    site_history.should be
    site_history.valid_to.should be_nil
    assert_properties(site_history, site)
    site_history.valid_since.to_i.should eq(site.updated_at.to_i)
  end

  it "shouldn't get current value for destroyed site" do
    site = Site.make
    site_copy = site
    site.destroy
    site_history = SiteHistory.get_current_value site_copy
    site_history.should be_nil
  end





end