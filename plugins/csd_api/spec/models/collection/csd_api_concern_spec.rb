require 'spec_helper'

describe Collection::CSDApiConcern do 
	let(:collection) { Collection.make }
	let(:layer) { collection.layers.make }

	describe 'csd_oid_field' do
		it 'is nil if there is no field with the right metadata' do
			collection.csd_oid.should be_nil
		end

		it 'chooses the right field given proper metadata configs' do
			oid_field = layer.identifier_fields.make(metadata: { "0" => { "key" => "CSDType", "value"=>"oid"} })

			collection.csd_oid.id.should eq(oid_field.id)
		end		
	end

	describe 'csd_coded_type_fields' do
		it '' do
			# F is a field that doesn't have CSD coded type semantics
			f = layer.select_one_fields.make

			# G is a list of fruit entries with coded type semantics
			g = layer.select_one_fields.make(
				config: {
					options: [
						{id: 1, code: "A", label: "Apple"}, 
						{id: 2, code: "B", label: "Banana"},
						{id: 3, code: "P", label: "Peach"}
					]	 
				}
			).csd_coded_type!("fruits")

			# H is a list of supermarkets with coded type semantics
			h = layer.select_one_fields.make(
				config: {
					options: [
						{id: 1, code: "C", label: "Carrefour"}, 
						{id: 2, code: "J", label: "Jumbo"}
					] 
				}
			).csd_coded_type!("supermarkets")

			csd_coded_type_fields = collection.csd_coded_types

			csd_coded_type_fields.should have(2).items
			csd_coded_type_fields.map(&:id).should include(g.id, h.id)
		end
	end
end