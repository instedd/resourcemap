require 'spec_helper'

describe Site do
  let!(:site) { Site.make properties: {'1' => '50', '2' => 'bla bla'}}
  let!(:fields) { [Field.make(id: '1', name: 'room'), Field.make(id: '2', name: 'des')] }

  it { should belong_to :collection }

  it_behaves_like "it includes History::Concern"

  it "return as a hash of field_name and its value" do
    site.get_field_value_hash.should eq({'room' => '50', 'des' => 'bla bla'})
  end
end
