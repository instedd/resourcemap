require 'spec_helper'

describe Collection::CSDApiConcern do 
	let(:collection) { Collection.make }
	let(:layer) { collection.layers.make }

	describe 'csd_facility_oid_field' do
		it 'is nil if there is no field with the right metadata' do
			collection.csd_facility_oid.should be_nil
		end

		it 'chooses the right field given proper metadata configs' do
			oid_field = layer.identifier_fields.make.csd_facility_oid!

			collection.csd_facility_oid.id.should eq(oid_field.id)
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

	describe 'csd_other_ids' do
		it '' do
			f = layer.identifier_fields.make
			g = layer.identifier_fields.make.csd_facility_oid!

			other_ids = collection.csd_other_ids

			other_ids.should have(1).item
			other_ids[0].id.should eq(f.id)
		end
	end

	describe 'csd_contacts' do
		it '' do
			f1 = layer.text_fields.make.csd_contact! "Contact 1"
			f2 = layer.text_fields.make.csd_contact! "Contact 1"
			f3 = layer.text_fields.make.csd_contact! "Contact 1"

			g1 = layer.text_fields.make.csd_contact! "Contact 2"
			g2 = layer.text_fields.make.csd_contact! "Contact 2"
			g3 = layer.text_fields.make.csd_contact! "Contact 2"

			contacts = collection.csd_contacts

			contacts.should have(2).items

			contacts[0].class.should be(CSDContactMapping)
			contacts[1].class.should be(CSDContactMapping)

			contacts[0].contact.should eq("Contact 1")
			contacts[0].all_components.map(&:id).should include(f1.id, f2.id, f3.id)

			contacts[1].contact.should eq("Contact 2")
			contacts[1].all_components.map(&:id).should include(g1.id, g2.id, g3.id)
		end
	end

	describe 'csd_organizations' do
		it '' do
			o1 = layer.text_fields.make.csd_organization("Org 1").csd_oid! 
			o2 = layer.text_fields.make.csd_organization("Org 2").csd_oid! 

			orgs = collection.csd_organizations

			orgs.should have(2).items

			orgs[0].class.should be(CSDOrganizationMapping)
			orgs[1].class.should be(CSDOrganizationMapping)
		end
	end
end