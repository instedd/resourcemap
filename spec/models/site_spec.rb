require 'spec_helper'

describe Site do
  it { should belong_to :collection }

  it_behaves_like "it includes History::Concern"

  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }
  let!(:layer) { collection.layers.make user: user }
  let!(:prop) { layer.fields.make :kind => 'select_one', :code => 'prop', :config => {'options' => [{'code' => 'foo', 'label' => 'A glass of water'}, {'code' => 'bar', 'label' => 'A bottle of wine'}]} }
  let!(:beds) { layer.fields.make :kind => 'numeric', :code => 'beds' }
  let!(:many) { layer.fields.make :kind => 'select_many', :code => 'prop', :config => {'options' => [{'code' => 'foo', 'label' => 'A glass of water'}, {'code' => 'bar', 'label' => 'A bottle of wine'}]} }

  it "converts properties values to int if the field is int" do
    site = collection.sites.make properties: {beds.es_code => '123'}
    site.properties[beds.es_code].should eq(123)
  end

  it "converts properties values to float if the field is float" do
    site = collection.sites.make properties: {beds.es_code => '123.4'}
    site.properties[beds.es_code].should eq(123.4)
  end

  it "convert select_many to ints" do
    site = collection.sites.make properties: {many.es_code => ['1', '2']}
    site.properties[many.es_code].should eq([1, 2])
  end

  it "removes empty properties after save" do
    site = collection.sites.make properties: {prop.es_code => 1, beds.es_code => nil}
    site.properties.should_not have_key(beds.es_code)
  end
end
