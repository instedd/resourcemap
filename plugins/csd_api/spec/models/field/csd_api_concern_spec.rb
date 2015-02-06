require 'spec_helper'
require_relative '../../csd_field_spec_helper'

describe Field::CSDApiConcern, :type => :model do
	include CSDFieldSpecHelper

	describe "configuring fields as CSD types" do
		it "turns a select one field into a CSD coded type" do
			f = Field::SelectOneField.make.csd_coded_type! "fruits"
			expect(f).to be_csd_coded_type
			expect(f.metadata_value_for("codingScheme")).to eq("fruits")
		end

		it "turns a identifier field into a CSD entityID" do
			f = Field::IdentifierField.make.csd_facility_entity_id!
			expect(f).to be_csd_facility_entity_id
		end

		it "turns a text field into a generic OID" do
			f = Field::TextField.make.csd_oid!("AnElementType")
			expect(f).to be_csd_oid("AnElementType")
		end

		it "turns a text field into a CSD name" do
			f = Field::TextField.make.csd_name!("a name", "parentTag")
			expect(f).to be_csd_name("parentTag")
			expect(f.metadata_value_for(Field::CSDApiConcern::csd_name_tag)).to eq("a name")
		end

		it "turns a field into a CSD Address" do
			f = Field::TextField.make.csd_address!("an address", "parentTag")
			expect(f).to be_csd_address("parentTag")
			expect(f.metadata_value_for(Field::CSDApiConcern::csd_address_tag)).to eq("an address")
		end

		describe "contact" do
			it "turns a field into part of a Contact element" do
				f = Field::TextField.make.csd_contact! "A contact"

				expect(f).to be_csd_contact
				expect(f.metadata_value_for("CSDCode")).to eq("A contact")
			end

			describe "name" do
				it "turns a text field into a common name" do
					f = Field::TextField.make.csd_common_name!("en")

					expect(f).to be_csd_common_name
					expect(f.metadata_value_for("language")).to eq("en")
				end

				it "turns a text field into a Surname" do
					f = Field::TextField.make.csd_surname!
					expect(f).to be_csd_surname
				end
			end

			describe "address" do
				it "turns a text field into an Address Line" do
					f = Field::TextField.make.csd_address_line! "streetLine"
					expect(f).to be_csd_address_line
					expect(f.metadata_value_for(Field::CSDApiConcern::csd_address_line_tag)).to eq("streetLine")
				end
			end
		end

		describe 'language' do
			it "turns a select one field into a CSD language field" do
				f = Field::SelectOneField.make.csd_language! "FooCodingSchema", "parentTag"
				expect(f).to be_csd_language("parentTag")
			end
		end
	end

	describe "CSD field metadata" do
		describe "oid" do
			let (:entity_id_field) { identifier_with_metadata({"CSDType" => "facilityEntityId"}) }

			it "is the facility's oid" do
			 	expect(entity_id_field).to be_csd_facility_entity_id
			end

			it "is not an otherId" do
				expect(entity_id_field).not_to be_csd_other_id
			end
		end

		it "coded type" do
			select_one_with_metadata({"CSDType" => "codedType", "codingScheme" => "foo"}) do |f|
				expect(f).to be_csd_coded_type
			end
		end

		it "facility type" do
			select_one_with_metadata({ "CSDType" => "facilityType", "OptionList" => "foo"}) do |f|
				expect(f).to be_csd_facility_type
			end
		end

		it "other name" do
			text_with_metadata({"CSDType" => "otherName"}) do |f|
				expect(f).to be_csd_other_name
			end
		end

		it "handles text field as contact point" do
			text_with_metadata({"CSDType" => "contactPoint"}) do |f|
				expect(f).to be_csd_contact_point
			end
		end

		it "handles select one field as contact point" do
			select_one_with_metadata({"CSDType" => "contactPoint"}) do |f|
				expect(f).to be_csd_contact_point
			end
		end

		it "language" do
			select_one_with_metadata({Field::CSDApiConcern::csd_language_tag => "language", "CSDChildOf" => "parentTag"}) do |f|
				expect(f).to be_csd_language("parentTag")
			end
		end

		it "status" do
			yes_no_with_metadata({"CSDType" => "status"}) do |f|
				expect(f).to be_csd_status
			end
		end

		describe "otherId" do
			it "is an identifier field" do
				expect(Field::IdentifierField.make).to be_csd_other_id
			end

			it "is not an entityID" do
				expect(Field::IdentifierField.make.csd_facility_entity_id!).not_to be_csd_other_id
			end
		end

		describe "contact" do
			it "contact top level" do
				text_with_metadata({"CSDType" => "contact", "CSDCode" => "a_code"}) do |f|
					expect(f).to be_csd_contact
				end
			end

			describe "name" do
				it "name top level" do
					text_with_metadata({Field::CSDApiConcern::csd_name_tag => "a_name", "CSDChildOf" => "parent"}) do |f|
						expect(f).to be_csd_name("parent")
					end
				end

				it "forename" do
					text_with_metadata({Field::CSDApiConcern::csd_forename_tag => "forename"}) do |f|
						expect(f).to be_csd_forename
					end
				end

				it "surname" do
					text_with_metadata({Field::CSDApiConcern::csd_surname_tag => "surname"}) do |f|
						expect(f).to be_csd_surname
					end
				end
			end
		end

		it "language" do
			select_one_with_metadata({Field::CSDApiConcern::csd_language_tag => "language", "codingSchema" => "FooCodingSchema", "CSDChildOf" => "parentTag"}) do |f|
				expect(f).to be_csd_language("parentTag")
				expect(f.metadata_value_for("codingSchema")).to eq("FooCodingSchema")
			end
		end

		describe "named elements" do
			it "it is an organization" do
				text_with_metadata({Field::CSDApiConcern::csd_organization_tag => "Org 1"}) do |f|
					expect(f).to be_csd_organization
					expect(f.csd_organization_element).to eq("Org 1")
				end
			end

			it "it is a service" do
				text_with_metadata({Field::CSDApiConcern::csd_service_tag => "Service 1"}) do |f|
					expect(f).to be_csd_service
					expect(f.csd_service_element).to eq("Service 1")
				end
			end

			it "it is a name" do
				text_with_metadata({Field::CSDApiConcern::csd_name_tag => "Name 1", "CSDChildOf" => "parentTag"}) do |f|
					expect(f).to be_csd_name("parentTag")
					expect(f.csd_name_element).to eq("Name 1")
				end
			end

			it "is an address" do
				text_with_metadata({Field::CSDApiConcern::csd_address_tag => "Address 1", "CSDChildOf" => "parentTag"}) do |f|
					expect(f).to be_csd_address("parentTag")
					expect(f.csd_address_element).to eq("Address 1")
				end
			end
		end
	end
end
