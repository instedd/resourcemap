require 'spec_helper'

describe Collection::ImportLayersSchemaConcern, :type => :model do
	let(:collection) { Collection.make }
	let(:other_collection) { Collection.make }
	let(:other_layer) { other_collection.layers.make name: "Adminsitrative Information", ord: 1, anonymous_user_permission: 'none' }

	let(:user) { User.make}

	it 'should import json_layer without fields' do
		json = [other_layer].to_json
		expect(collection.layers.count).to eq(0)
		Timecop.travel(2.seconds.from_now)
		collection.import_schema(json, user)
		expect(collection.layers.count).to eq(1)
		collection_new_layer = collection.layers.first
		expect(collection_new_layer.name).to eq("Adminsitrative Information")
		expect(collection_new_layer.ord).to eq(1)
		expect(collection_new_layer.id).not_to eq(other_layer.id)
		expect(collection_new_layer.collection_id).not_to eq(other_layer.collection_id)
		expect(collection_new_layer.created_at).not_to eq(other_layer.created_at)
		expect(collection_new_layer.updated_at).not_to eq(other_layer.updated_at)
		expect(collection_new_layer.anonymous_user_permission).to eq('none')
	end

	it 'should import json_layer with numeric field' do
		other_layer.numeric_fields.make code: 'numBeds', name: 'Number of Beds', config: { :allows_decimals => "true" }
		other_field = other_layer.fields.first
		json = other_collection.layers.includes(:fields).to_json(include: :fields)
		Timecop.travel(2.seconds.from_now)
		collection.import_schema(json, user)
		expect(collection.fields.count).to eq(1)
		new_field = collection.fields.first
		expect(new_field.code).to eq('numBeds')
		expect(new_field.name).to eq('Number of Beds')
		expect(new_field.kind).to eq('numeric')
		expect(new_field.updated_at).not_to eq(other_field.updated_at)
		expect(new_field.id).not_to eq(other_field.id)
		expect(new_field.collection_id).not_to eq(other_field.collection_id)
		expect(new_field.collection_id).to eq(collection.id)
		expect(new_field.allow_decimals?).to eq(true)
	end

	it 'should import json_layer with options field' do
		config_hierarchy = [{ id: '1', name: 'Dad', sub: [{id: '2', name: 'Son'}, {id: '3', name: 'Bro'}]}]
  	other_layer.hierarchy_fields.make :code => 'family', config: { hierarchy: config_hierarchy }.with_indifferent_access
  	other_field = other_layer.fields.first
  	json = other_collection.layers.includes(:fields).to_json(include: :fields)
		collection.import_schema(json, user)
		expect(collection.fields.count).to eq(1)
		new_field = collection.fields.first
		expect(new_field.hierarchy_options.length).to eq(3)
	end

end
