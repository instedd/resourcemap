module Collection::CSDApiConcern
  extend ActiveSupport::Concern

  def facility_type_fields
    select_one_fields.select{|field| field.metadata["Type"] == "facilityType" && (field.metadata.has_key?("OptionList")) }
  end
end
