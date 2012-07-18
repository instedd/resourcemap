require 'spec_helper'

describe Site do
  let(:layer) { Layer.make }
  let(:field1) { layer.fields.make(name: 'room') }
  let(:field2) { layer.fields.make(name: 'des') }
  let(:site) { layer.collection.sites.make properties: {field1.id.to_s => '50', field2.id.to_s => 'bla bla'}}

  it { should belong_to :collection }

  it_behaves_like "it includes History::Concern"

  it "return as a hash of field_name and its value" do
    site.human_properties.should eq({'room' => '50', 'des' => 'bla bla'})
  end
end
