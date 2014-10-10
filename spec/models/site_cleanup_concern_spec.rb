require 'spec_helper'

describe Site::CleanupConcern, :type => :model do
  let(:user) { User.make }
  let(:collection) { user.create_collection Collection.make_unsaved }
  let(:layer) { collection.layers.make user: user }
  let(:beds) { layer.numeric_fields.make :code => 'beds' }
  let(:area) { layer.numeric_fields.make :code => 'area', config: { :allows_decimals => "true" }  }
  let(:many) { layer.select_many_fields.make :code => 'many', :config => {'options' => [{'id' => 1, 'code' => 'foo', 'label' => 'A glass of water'}, {'id' => 2, 'code' => 'bar', 'label' => 'A bottle of wine'}]} }
  let(:one) { layer.select_one_fields.make :code => 'one', :config => {'options' => [{'id' => 1, 'code' => 'foo', 'label' => 'A glass of water'}, {'id' => 2, 'code' => 'bar', 'label' => 'A bottle of wine'}]} }

  it "converts properties values to int if the field does not allow decimals" do
    site = collection.sites.make properties: {beds.es_code => '123'}
    expect(site.properties[beds.es_code]).to eq(123)
  end

  it "converts properties values to float if the field allows decimals" do
    site = collection.sites.make properties: {area.es_code => '123.4'}
    expect(site.properties[area.es_code]).to eq(123.4)
  end

  it "convert select_many to ints" do
    site = collection.sites.make properties: {many.es_code => ['1', '2']}
    expect(site.properties[many.es_code]).to eq([1, 2])
  end

  it "convert select_one to ints" do
    site = collection.sites.make properties: {one.es_code => '1'}
    expect(site.properties[one.es_code]).to eq(1)
  end

  it "removes empty properties after save" do
    site = collection.sites.make properties: { beds.es_code => nil}
    expect(site.properties).not_to have_key(beds.es_code)
  end

  it "should translate latitude from GPS coordinates" do
    site = collection.sites.make lat: '35.8 N'
    site.lat.to_f.should eq(35.8)

    site = collection.sites.make lat: '65.924S'
    site.lat.to_f.should eq(-65.924)
  end

  it "should translate longitude from GPS coordinates" do
    site = collection.sites.make lng: '35.85790E'
    site.lng.to_f.should eq(35.8579)

    site = collection.sites.make lng: '65.92 w'
    site.lng.to_f.should eq(-65.92)
  end

end

