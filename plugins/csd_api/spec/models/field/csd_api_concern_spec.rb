require 'spec_helper'
require_relative '../../csd_field_spec_helper'

describe Field::CSDApiConcern do 
	include CSDFieldSpecHelper

	describe "configuring fields as CSD types" do
		it "turns a select one field into a CSD coded type" do
			f = Field::SelectOneField.make.csd_coded_type! "fruits"
			f.should be_csd_coded_type
			f.metadata_value_for("codingSchema").should eq("fruits")
		end

		it "turns a identifier field into a CSD OID" do
			f = Field::IdentifierField.make.csd_facility_oid!
			f.should be_csd_facility_oid
		end

		it "turns a text field into a generic OID" do
			f = Field::TextField.make.csd_oid!("AnElementType")
			f.should be_csd_oid("AnElementType")
		end

		it "turns a text field into a CSD name" do
			f = Field::TextField.make.csd_name!("a name", "parentTag")
			f.should be_csd_name("parentTag")
			f.metadata_value_for(Field::CSDApiConcern::csd_name_tag).should eq("a name")
		end

		it "turns a field into a CSD Address" do
			f = Field::TextField.make.csd_address!("an address", "parentTag")
			f.should be_csd_address("parentTag")
			f.metadata_value_for(Field::CSDApiConcern::csd_address_tag).should eq("an address")
		end

		describe "contact" do
			it "turns a field into part of a Contact element" do
				f = Field::TextField.make.csd_contact! "A contact"
	 
				f.should be_csd_contact
				f.metadata_value_for("CSDCode").should eq("A contact")
			end

			describe "name" do
				it "turns a text field into a common name" do
					f = Field::TextField.make.csd_common_name!("en")

					f.should be_csd_common_name
					f.metadata_value_for("language").should eq("en")
				end

				it "turns a text field into a Surname" do
					f = Field::TextField.make.csd_surname!
					f.should be_csd_surname
				end
			end

			describe "address" do
				it "turns a text field into an Address Line" do 
					f = Field::TextField.make.csd_address_line! "streetLine"
					f.should be_csd_address_line
					f.metadata_value_for(Field::CSDApiConcern::csd_address_line_tag).should eq("streetLine")
				end
			end
		end

		describe 'language' do
			it "turns a select one field into a CSD language field" do
				f = Field::SelectOneField.make.csd_language! "FooCodingSchema"
				f.should be_csd_language
			end
		end
	end

	describe "CSD field metadata" do
		describe "oid" do
			let (:oid_field) { identifier_with_metadata({"CSDType" => "facilityOid"}) }

			it "is the facility's oid" do
			 	oid_field.should be_csd_facility_oid
			end

			it "is not an otherId" do
				oid_field.should_not be_csd_other_id
			end
		end		

		it "coded type" do
			select_one_with_metadata({"CSDType" => "codedType", "codingSchema" => "foo"}) do |f|
				f.should be_csd_coded_type
			end
		end

		it "facility type" do
			select_one_with_metadata({ "CSDType" => "facilityType", "OptionList" => "foo"}) do |f|
				f.should be_csd_facility_type
			end
		end

		it "other name" do
			text_with_metadata({"CSDType" => "otherName"}) do |f|
				f.should be_csd_other_name
			end
		end

		it "handles text field as contact point" do
			text_with_metadata({"CSDType" => "contactPoint"}) do |f|
				f.should be_csd_contact_point
			end
		end

		it "handles select one field as contact point" do
			select_one_with_metadata({"CSDType" => "contactPoint"}) do |f|
				f.should be_csd_contact_point
			end
		end		

		it "language" do
			select_one_with_metadata({"CSDType" => "language"}) do |f|
				f.should be_csd_language
			end
		end

		it "status" do
			yes_no_with_metadata({"CSDType" => "status"}) do |f|
				f.should be_csd_status
			end
		end

		describe "otherId" do
			it "is an identifier field" do
				Field::IdentifierField.make.should be_csd_other_id
			end

			it "is not an oid" do
				Field::IdentifierField.make.csd_facility_oid!.should_not be_csd_other_id
			end
		end

		describe "contact" do
			it "contact top level" do
				text_with_metadata({"CSDType" => "contact", "CSDCode" => "a_code"}) do |f|
					f.should be_csd_contact
				end
			end

			describe "name" do
				it "name top level" do
					text_with_metadata({Field::CSDApiConcern::csd_name_tag => "a_name", "CSDChildOf" => "parent"}) do |f|
						f.should be_csd_name("parent")
					end
				end

				it "forename" do
					text_with_metadata({Field::CSDApiConcern::csd_forename_tag => "forename"}) do |f|
						f.should be_csd_forename
					end
				end

				it "surname" do
					text_with_metadata({Field::CSDApiConcern::csd_surname_tag => "surname"}) do |f|
						f.should be_csd_surname
					end
				end
			end
		end

		it "language" do
			select_one_with_metadata({"CSDType" => "language", "codingSchema" => "FooCodingSchema"}) do |f|
				f.should be_csd_language
				f.metadata_value_for("codingSchema").should eq("FooCodingSchema")
			end
		end

		describe "named elements" do
			it "it is an organization" do
				text_with_metadata({Field::CSDApiConcern::csd_organization_tag => "Org 1"}) do |f|
					f.should be_csd_organization
					f.csd_organization_element.should eq("Org 1")
				end
			end

			it "it is a service" do
				text_with_metadata({Field::CSDApiConcern::csd_service_tag => "Service 1"}) do |f|
					f.should be_csd_service
					f.csd_service_element.should eq("Service 1")
				end
			end

			it "it is a name" do
				text_with_metadata({Field::CSDApiConcern::csd_name_tag => "Name 1", "CSDChildOf" => "parentTag"}) do |f|
					f.should be_csd_name("parentTag")
					f.csd_name_element.should eq("Name 1")
				end
			end

			it "is an address" do
				text_with_metadata({Field::CSDApiConcern::csd_address_tag => "Address 1", "CSDChildOf" => "parentTag"}) do |f|
					f.should be_csd_address("parentTag")
					f.csd_address_element.should eq("Address 1")
				end
			end
		end
	end
end