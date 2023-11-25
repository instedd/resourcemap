require 'spec_helper'

describe Site::PrefixConcern, :type => :model do
  it "should get first id_with_prefix" do
    site = Site.make_unsaved
    expect(site.generate_id_with_prefix).to eq('AA1')
  end

  it "should get id_with_prefix" do
    site = Site.make
    site.id_with_prefix = "AW22" and site.save
    expect(site.generate_id_with_prefix).to eq('AW23')
  end

  it "should get id with two prefixex" do
    site = Site.make(:id_with_prefix => 'AD999')
    prefix_and_id = site.get_id_with_prefix
    expect(prefix_and_id.size).to eq(2)
    expect(prefix_and_id[0]).to eq('AD')
    expect(prefix_and_id[1]).to eq('999')
  end
end

