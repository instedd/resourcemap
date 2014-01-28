require 'spec_helper'

describe CSDOrganizationMapping do
	describe 'oid' do
		let(:oid_field) { Field::TextField.make.csd_organization("Org1").csd_oid!(Field::CSDApiConcern::csd_organization_tag) }

		it '' do
			m = CSDOrganizationMapping.new "Org1", [oid_field]
			m.oid.id.should eq(oid_field.id)
		end

		it "doesn't use oid attributes from child entities" do
			child_oid_field1 = Field::TextField.make.csd_service("S1").csd_oid!(Field::CSDApiConcern::csd_service_tag)
			child_oid_field2 = Field::TextField.make.csd_service("S2").csd_oid!(Field::CSDApiConcern::csd_service_tag) 

			m = CSDOrganizationMapping.new "Org1", [oid_field, child_oid_field1, child_oid_field2]
			m.oid.id.should eq(oid_field.id)

			#Just to make sure that it's not matter of order, we test changing the order of fields
			m = CSDOrganizationMapping.new "Org1", [child_oid_field1, child_oid_field2, oid_field]
			m.oid.id.should eq(oid_field.id)
		end
	end

	describe 'services' do
		it '' do
			service_field1 = Field::TextField.make.csd_service!("Service 1")
			service_field2 = Field::TextField.make.csd_service!("Service 2")

			m = CSDOrganizationMapping.new "Org1", [service_field1, service_field2]

			m.services.should have(2).items
			m.services[0].class.should be(CSDServiceMapping)
			m.services[1].class.should be(CSDServiceMapping)
		end
	end
end