module Collection::CSDApiConcern
  extend ActiveSupport::Concern

  def csd_oid_field
    identifier_fields.find do |field|
      (!field.metadata.blank?) && (entry(field.metadata,"CSDType") == "oid" )
    end
  end

  def facility_type_fields
    select_one_fields.select do |field|
      (!field.metadata.blank?) && (entry(field.metadata,"CSDType") == "facilityType" ) && has_entry(field.metadata, "OptionList")
    end
  end

  def facility_other_name_fields
    text_fields.select do |field|
     (!field.metadata.blank?) && (entry(field.metadata, "CSDType") == "otherName")
    end
  end

  def facility_address_fields
    text_fields.select do |field|
      (!field.metadata.blank?)  && (entry(field.metadata, "CSDType") == "address")
    end.group_by{|field| entry(field.metadata, "CSDCode")}
  end

  def facility_contact_point_fields
    text_fields.select do |field|
      (!field.metadata.blank?) && (entry(field.metadata, "CSDType") == "contactPoint")
    end.group_by{|field| entry(field.metadata,"CSDCode")}
  end

  def coded_type_for_contact_point_fields
    select_one_fields.select do |field|
      (!field.metadata.blank?) && (entry(field.metadata,"CSDType") == "contactPoint")
    end.group_by{|field| entry(field.metadata,"CSDCode")}
  end

  def facility_language_fields
    select_one_fields.select do |field|
      (!field.metadata.blank?) && (entry(field.metadata, "CSDType") == "language")
    end
  end

  def facility_status_field
    yes_no_fields.find do |field|
      (!field.metadata.blank?) && (entry(field.metadata, "CSDType") == "status")
    end
  end

  def entry(metadata, metadata_key)
    if has_entry(metadata, metadata_key)
      metadata_entry = metadata.values.find{|element| element["key"] == metadata_key}
      metadata_entry["value"]
    end
  end

  def has_entry(metadata, metadata_key)
    metadata.values.find{|element| element["key"] == metadata_key}
  end
end
