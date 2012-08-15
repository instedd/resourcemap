require 'spec_helper'

describe Site do
  let(:user) { User.make }
  it { should belong_to :collection }
  it_behaves_like "it includes History::Concern"

  let(:collection) { Collection.make }
  let(:layer) { collection.layers.make }
  let(:room) { layer.fields.make name: 'room'  }
  let(:desk) { layer.fields.make name: 'desk'  }
  let(:site) { collection.sites.make properties: { room.id.to_s => '50', desk.id.to_s => 'bla bla' } }

  it "return as a hash of field_name and its value" do
    site.human_properties.should eq({'room' => '50', 'desk' => 'bla bla'})
  end

  describe "create or update from hash" do
    before(:each) do
      @hash = { "collection_id" => layer.collection.id, 
        "name" => "site1", "lat" =>  "11.1", "lng" => "12.1", 
        "existing_fields" => {"field_#{room.id}" => {"field_id" => room.id, "value" => "10"},
          "field_#{desk.id}" => {"field_id" => desk.id, "value" => "test"}}}
      @hash.merge!("current_user" => user)
      @site_count = Site.count
    end

    it "should create a new site when site id is missing or nil" do
      site1 = Site.create_or_update_from_hash!(@hash)
      site1.should_not be_nil
    end

    it "should update an existing site" do
      @hash["site_id"] = site.id
      site1 = Site.create_or_update_from_hash!(@hash)
      site1.name.should eq(@hash["name"])
    end
  end
  
  it "should get id and name" do
    Site.get_id_and_name([site.id]).should eq([{'id' => site.id, 'name' => site.name}]) 
  end

end
