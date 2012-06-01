require 'spec_helper'

describe SiteHistory do
  it { should belong_to :site }

  it "should create from site" do

    site = Site.make
    site_history = SiteHistory.create_from_site site
    site_history.site_id.should == site.id
    site_history.collection_id.should == site.collection_id
    site_history.name.should == site.name
    site_history.lat.should == site.lat
    site_history.lng.should == site.lng
    site_history.parent_id.should == site.parent_id
    site_history.hierarchy.should == site.hierarchy
    site_history.properties.should == site.properties
    site_history.location_mode.should == site.location_mode
    site_history.id_with_prefix.should == site.id_with_prefix
    site_history.valid_to.should == nil
    site_history.valid_since.to_i.should eq(site.created_at.to_i)

  end


end