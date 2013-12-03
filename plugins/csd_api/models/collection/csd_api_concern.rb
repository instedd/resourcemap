module Collection::CSDApiConcern
  extend ActiveSupport::Concern

  def facility_type_fields
    select_one_fields.select{|field| field.metadata["CSDType"] == "facilityType" && (field.metadata.has_key?("OptionList")) }
  end

  def facility_other_name_fields
    text_fields.select{|field| field.metadata["CSDType"] == "otherName" }
  end

  def facility_address_fields
    text_fields.select{|field| field.metadata["CSDType"] == "address" }.group_by{|field| field.metadata["CSDCode"]}
  end

  def facility_contact_point_fields
    text_fields.select{|field| field.metadata["CSDType"] == "contactPoint" }.group_by{|field| field.metadata["CSDCode"]}
  end

  def coded_type_for_contact_point_fields
    select_one_fields.select{|field| field.metadata["CSDType"] == "contactPoint" }.group_by{|field| field.metadata["CSDCode"]}
  end

  def facility_language_fields
    select_one_fields.select{|field| field.metadata["CSDType"] == "language" }
  end

  def facility_status_field
    yes_no_fields.find{|field| field.metadata["CSDType"] == "status"}
  end
end
