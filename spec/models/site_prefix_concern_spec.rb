require 'spec_helper'

describe Site::PrefixConcern do
  it "should get first id_with_prefix" do
    site = Site.make_unsaved
    site.generate_id_with_prefix.should == 'AA1'
  end

  it "should get id_with_prefix" do
    site = Site.make
    site.id_with_prefix = "AW22" and site.save
    site.generate_id_with_prefix.should == 'AW23'
  end

  it "should get id with two prefixex" do
    site = Site.make(:id_with_prefix => 'AD999')
    prefix_and_id = site.get_id_with_prefix
    prefix_and_id.size.should == 2
    prefix_and_id[0].should == 'AD'
    prefix_and_id[1].should == '999'
  end
end

