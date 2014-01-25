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
		it "oid" do
			identifier_with_metadata({"CSDType" => "oid"}) do |f|
				f.should be_csd_oid
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
	end
end