require 'spec_helper'

describe Collection::CSDApiConcern, :type => :model do
	let(:collection) { Collection.make }
	let(:layer) { collection.layers.make }

	describe 'csd_facility_entity_id_field' do
		it 'is nil if there is no field with the right metadata' do
			expect(collection.csd_facility_entity_id).to be_nil
		end

		it 'chooses the right field given proper metadata configs' do
			entity_id_field = layer.identifier_fields.make.csd_facility_entity_id!

			expect(collection.csd_facility_entity_id.id).to eq(entity_id_field.id)
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

			expect(csd_coded_type_fields.size).to eq(2)
			expect(csd_coded_type_fields.map(&:id)).to include(g.id, h.id)
		end
	end

	describe 'csd_other_ids' do
		it '' do
			f = layer.identifier_fields.make
			g = layer.identifier_fields.make.csd_facility_entity_id!

			other_ids = collection.csd_other_ids

			expect(other_ids.size).to eq(1)
			expect(other_ids[0].id).to eq(f.id)
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

			expect(contacts.size).to eq(2)

			expect(contacts[0].class).to be(CSDContactMapping)
			expect(contacts[1].class).to be(CSDContactMapping)

			expect(contacts[0].contact).to eq("Contact 1")
			expect(contacts[0].all_components.map(&:id)).to include(f1.id, f2.id, f3.id)

			expect(contacts[1].contact).to eq("Contact 2")
			expect(contacts[1].all_components.map(&:id)).to include(g1.id, g2.id, g3.id)
		end
	end

	describe 'csd_organizations' do
		it '' do
			o1 = layer.text_fields.make.csd_organization("Org 1").csd_oid!(Field::CSDApiConcern::csd_organization_tag)
			o2 = layer.text_fields.make.csd_organization("Org 2").csd_oid!(Field::CSDApiConcern::csd_organization_tag)

			orgs = collection.csd_organizations

			expect(orgs.size).to eq(2)

			expect(orgs[0].class).to be(CSDOrganizationMapping)
			expect(orgs[1].class).to be(CSDOrganizationMapping)
		end
	end
end
