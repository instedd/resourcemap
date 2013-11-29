module Collection::CSDApiConcern
  extend ActiveSupport::Concern

  def facility_type_fields
    select_one_fields.select{|field| field.metadata["CSDType"] == "facilityType" && (field.metadata.has_key?("OptionList")) }
  end

  def facility_other_name_fields
    text_fields.select{|field| field.metadata["CSDType"] == "otherName" }
  end

  def facility_address_fields
    text_fields.select{|field| field.metadata["CSDType"] == "address" }
  end
end
