module Collection::CSDApiConcern
  extend ActiveSupport::Concern

  def csd_oid
    identifier_fields.find(&:csd_oid?)
  end

  def csd_coded_types
    select_one_fields.select(&:csd_coded_type?)
  end

  def csd_facility_types
    select_one_fields.select(&:csd_facility_type?)
  end

  def csd_other_names
    text_fields.select(&:csd_other_name?)
  end

  def csd_addresses
    text_fields.select(&:csd_address?).group_by {|f| f.metadata_value_for("CSDCode") }
  end

  def csd_text_contact_points
    csd_contact_points_in text_fields
  end

  def csd_select_one_contact_points
    csd_contact_points_in select_one_fields
  end

  def csd_languages
    select_one_fields.select(&:csd_language?)
  end

  def csd_status
    yes_no_fields.find(&:csd_status?)
  end

  private 

  def csd_contact_points_in(fields)
    fields.select(&:csd_contact_point?).group_by {|f| f.metadata_value_for("CSDCode") }
  end
end
