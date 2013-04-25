require 'spec_helper'

describe Site::CleanupConcern do
  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }
  let!(:layer) { collection.layers.make user: user }
  let!(:beds) { layer.numeric_fields.make :code => 'beds' }
  let!(:area) { layer.numeric_fields.make :code => 'area', config: { :allows_decimals => "true" }  }
  let!(:many) { layer.select_many_fields.make :code => 'many', :config => {'options' => [{'id' => 1, 'code' => 'foo', 'label' => 'A glass of water'}, {'id' => 2, 'code' => 'bar', 'label' => 'A bottle of wine'}]} }
  let!(:one) { layer.select_one_fields.make :code => 'one', :config => {'options' => [{'id' => 1, 'code' => 'foo', 'label' => 'A glass of water'}, {'id' => 2, 'code' => 'bar', 'label' => 'A bottle of wine'}]} }

  it "converts properties values to int if the field does not allow decimals" do
    site = collection.sites.make properties: {beds.es_code => '123'}
    site.properties[beds.es_code].should eq(123)
  end

  it "converts properties values to float if the field allows decimals" do
    site = collection.sites.make properties: {area.es_code => '123.4'}
    site.properties[area.es_code].should eq(123.4)
  end

  it "convert select_many to ints" do
    site = collection.sites.make properties: {many.es_code => ['1', '2']}
    site.properties[many.es_code].should eq([1, 2])
  end

  it "convert select_one to ints" do
    site = collection.sites.make properties: {one.es_code => '1'}
    site.properties[one.es_code].should eq(1)
  end

  it "removes empty properties after save" do
    site = collection.sites.make properties: { beds.es_code => nil}
    site.properties.should_not have_key(beds.es_code)
  end
end

