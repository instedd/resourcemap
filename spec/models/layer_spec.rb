require 'spec_helper'

describe Layer do
  it { should belong_to :collection }
  it { should have_many :fields }

  context "when layer fields code change" do
    let(:collection) { Collection.make }
    let!(:layer) { collection.layers.make }
    let!(:field1) { layer.fields.make collection_id: collection.id, name: 'Field 1', code: 'field1' }
    let!(:field2) { layer.fields.make collection_id: collection.id, name: 'Field 2', code: 'field2' }
    let!(:field3) { layer.fields.make collection_id: collection.id, name: 'Field 3', code: 'field3' }

    it "should change site properties" do
      collection.update_mapping

      site1 = collection.sites.make :properties => {'field1' => '1', 'field2' => '2', 'field3' => '3'}
      site2 = collection.sites.make :properties => {'field1' => '4', 'field2' => '5', 'field3' => '6'}

      layer.update_attributes :fields_attributes => [{id: field1.id, code: 'field11'}, {id: field3.id, code: 'field33'}]

      site1.reload
      site1.properties.should eq({'field11' => '1', 'field2' => '2', 'field33' => '3'})

      site2.reload
      site2.properties.should eq({'field11' => '4', 'field2' => '5', 'field33' => '6'})
    end

    it "should change site properties when swapping codes" do
      collection.update_mapping

      site1 = collection.sites.make :properties => {'field1' => '1', 'field2' => '2', 'field3' => '3'}
      site2 = collection.sites.make :properties => {'field1' => '4', 'field2' => '5', 'field3' => '6'}

      layer.update_attributes :fields_attributes => [{id: field1.id, code: 'field3'}, {id: field3.id, code: 'field1'}]

      site1.reload
      site1.properties.should eq({'field3' => '1', 'field2' => '2', 'field1' => '3'})

      site2.reload
      site2.properties.should eq({'field3' => '4', 'field2' => '5', 'field1' => '6'})
    end

    it "should change site properties when almost swapping codes" do
      collection.update_mapping

      site1 = collection.sites.make :properties => {'field1' => '1', 'field2' => '2', 'field3' => '3'}
      site2 = collection.sites.make :properties => {'field1' => '4', 'field2' => '5', 'field3' => '6'}

      layer.update_attributes :fields_attributes => [{id: field1.id, code: 'field2'}, {id: field2.id, code: 'field22'}]

      site1.reload
      site1.properties.should eq({'field2' => '1', 'field22' => '2', 'field3' => '3'})

      site2.reload
      site2.properties.should eq({'field2' => '4', 'field22' => '5', 'field3' => '6'})
    end

    it "should change site properties when transitioning codes" do
      collection.update_mapping

      site1 = collection.sites.make :properties => {'field1' => '1', 'field2' => '2', 'field3' => '3'}
      site2 = collection.sites.make :properties => {'field1' => '4', 'field2' => '5', 'field3' => '6'}

      layer.update_attributes :fields_attributes => [{id: field1.id, code: 'field2'}, {id: field2.id, code: 'field3'}, {id: field3.id, code: 'field1'}]

      site1.reload
      site1.properties.should eq({'field2' => '1', 'field3' => '2', 'field1' => '3'})

      site2.reload
      site2.properties.should eq({'field2' => '4', 'field3' => '5', 'field1' => '6'})
    end
  end
end
