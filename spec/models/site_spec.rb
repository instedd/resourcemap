require 'spec_helper'

describe Site do
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
  
  it "should get id and name" do
    Site.get_id_and_name([site.id]).should eq([{'id' => site.id, 'name' => site.name}]) 
  end
end
