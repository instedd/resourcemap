require 'spec_helper'

describe Site, :type => :model do
  let(:user) { User.make }
  it { is_expected.to belong_to :collection }

  def history_concern_class
    described_class
  end

  def history_concern_foreign_key
    described_class.name.foreign_key
  end

  def history_concern_histories
    "#{described_class}_histories"
  end

  it_behaves_like "it includes History::Concern"

  let(:collection) { Collection.make }
  let(:layer) { collection.layers.make }
  let(:room) { layer.numeric_fields.make name: 'room'  }
  let(:desk) { layer.text_fields.make name: 'desk'  }
  let(:creation) { layer.date_fields.make name: 'creation'}

  let(:site) { collection.sites.make properties: { room.id.to_s => '50', desk.id.to_s => 'bla bla', creation.id.to_s => '2012-09-22T00:00:00Z' } }

  it "return as a hash of field_name and its value" do
    expect(site.human_properties).to eq({'room' => 50, 'desk' => 'bla bla', 'creation' => '09/22/2012' })
  end

  it "should save yes_no property with value 'false' "  do
    yes_no_field = layer.yes_no_fields.make :code => 'X Ray machine'
    site.properties[yes_no_field.es_code] = false
    site.save!
    site.reload
    expect(site.properties[yes_no_field.es_code]).to eq(false)
  end

  describe "create or update from hash" do
    before(:each) do
      @hash = { "collection_id" => layer.collection.id,
        "name" => "site1", "lat" =>  "11.1", "lng" => "12.1",
        "existing_fields" => {"field_#{room.id}" => {"field_id" => room.id, "value" => "10"},
          "field_#{desk.id}" => {"field_id" => desk.id, "value" => "test"}}, "current_user" => user}
      @site_count = Site.count
    end

    it "should create a new site when site id is missing or nil" do
      site1 = Site.create_or_update_from_hash!(@hash)
      expect(site1).not_to be_nil
    end

    it "should update an existing site" do
      @hash["site_id"] = site.id
      site1 = Site.create_or_update_from_hash!(@hash)
      expect(site1.name).to eq(@hash["name"])
    end
  end

  it "should get id and name" do
    expect(Site.get_id_and_name([site.id])).to eq([{'id' => site.id, 'name' => site.name}])
  end

  it "should save without problems after field is deleted" do
    site # This line is needed because let(:site) is lazy

    room.destroy

    site.properties = site.properties
    site.save!
  end

  it "should have version" do
    expect(site.version).to eq(1)
  end

  it "should increase version if something changes in the site" do
    site.name = "other name"
    site.save!

    expect(site.version).to eq(2)
  end
end
