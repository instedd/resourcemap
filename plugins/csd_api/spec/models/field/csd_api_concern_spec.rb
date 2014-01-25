require 'spec_helper'
require_relative '../../csd_field_spec_helper'

describe Field::CSDApiConcern do 
	include CSDFieldSpecHelper

	describe "configuring fields as CSD types" do
		it "turns a select one field into a CSD coded type" do
			f = Field::SelectOneField.make

			f.csd_coded_type! "fruits"

			f.should be_csd_coded_type
			f.metadata_value_for("codingSchema").should eq("fruits")
		end

		it "turns a identifier field into a CSD OID" do
			f = Field::IdentifierField.make

			f.csd_oid!

			f.should be_csd_oid
		end
	end

	describe "CSD field metadata" do
		describe "oid" do
			let (:oid_field) { identifier_with_metadata({"CSDType" => "oid"}) }

			it "is an oid" do
			 	oid_field.should be_csd_oid
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

		it "address" do
			text_with_metadata({"CSDType" => "address"}) do |f|
				f.should be_csd_address
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
				Field::IdentifierField.make.csd_oid!.should_not be_csd_other_id
			end
		end
	end
end