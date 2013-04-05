require 'spec_helper'

describe Collection::ImportLayersSchemaConcern do
	let(:collection) { Collection.make }
	let(:other_collection) { Collection.make }
	let(:other_layer) { other_collection.layers.make name: "Adminsitrative Information", ord: 1, public: false }

	let(:user) { User.make}

	it 'should import json_layer without fields' do
		json = [other_layer].to_json
		collection.layers.count.should eq(0)
		sleep 2
		collection.import_schema(json, user)
		collection.layers.count.should eq(1)
		collection_new_layer = collection.layers.first
		collection_new_layer.name.should eq("Adminsitrative Information")
		collection_new_layer.ord.should eq(1)
		collection_new_layer.id.should_not eq(other_layer.id)
		collection_new_layer.collection_id.should_not eq(other_layer.collection_id)
		collection_new_layer.created_at.should_not eq(other_layer.created_at)
		collection_new_layer.updated_at.should_not eq(other_layer.updated_at)
		collection_new_layer.public.should eq(false)
	end

	it 'should import json_layer with numeric field' do
		other_layer.numeric_fields.make code: 'numBeds', name: 'Number of Beds', config: { :allows_decimals => "true" } 
		other_field = other_layer.fields.first
		json = other_collection.layers.includes(:fields).to_json(include: :fields)
		sleep 2
		collection.import_schema(json, user)
		collection.fields.count.should eq(1)
		new_field = collection.fields.first
		new_field.code.should eq('numBeds')
		new_field.name.should eq('Number of Beds')
		new_field.kind.should eq('numeric')
		new_field.updated_at.should_not eq(other_field.updated_at)
		new_field.id.should_not eq(other_field.id)
		new_field.collection_id.should_not eq(other_field.collection_id)
		new_field.collection_id.should eq(collection.id)
		new_field.allow_decimals?.should eq(true)
	end

	it 'should import json_layer with options field' do
		config_hierarchy = [{ id: '1', name: 'Dad', sub: [{id: '2', name: 'Son'}, {id: '3', name: 'Bro'}]}]
  	other_layer.hierarchy_fields.make :code => 'family', config: { hierarchy: config_hierarchy }.with_indifferent_access
  	other_field = other_layer.fields.first
  	json = other_collection.layers.includes(:fields).to_json(include: :fields)
		collection.import_schema(json, user)
		collection.fields.count.should eq(1)
		new_field = collection.fields.first
		new_field.hierarchy_options.length.should eq(3)
	end
	
end