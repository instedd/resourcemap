require 'spec_helper'

describe Site do
  it { should belong_to :collection }

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

  it "should get first id_with_prefix" do
    site = Site.make_unsaved
    site.generate_id_with_prefix.should == 'AA1'
  end

  it "should get id_with_prefix" do
    site = Site.make
    site.id_with_prefix = "AW22" and site.save
    site.generate_id_with_prefix.should == 'AW23'
  end

  it "should get id with prefix" do
    site = Site.make(:id_with_prefix => 'AD999')
    prefix_and_id = site.get_id_with_prefix
    prefix_and_id.size.should == 2
    prefix_and_id[0].should == 'AD'
    prefix_and_id[1].should == '999'
  end

  it "should store history on creation" do
    site = Site.make_unsaved
    site.histories.count.should == 0
    site.save!
    site.histories.count.should == 1
  end

  it "should store history on update" do
    site = Site.make
    site.histories.count.should == 1
    site.name = "New name"
    site.save!
    site.name.should == "New name"
    site.histories.count.should == 2
    site.histories.last.name.should == "New name"
  end

  it "should set valid_to in history on update" do
    site = Site.make
    site.name = "New name"
    site.save!
    site.histories.count.should == 2
    site.histories.first.valid_to.to_i.should eq(site.updated_at.to_i)
    site.histories.last.valid_to.should be_nil
  end

  it "should set valid_to in history before delete" do
    site = Site.make
    site.histories.count.should == 1
    site.histories.last.valid_to.should be_nil
    site_id = site.id
    site.destroy
    histories = site.histories.all
    Site.find_all_by_id(site_id).count.should == 0
    histories.count.should == 1
    histories.last.valid_to.to_i.should eq(Time.now.to_i)
  end
end
