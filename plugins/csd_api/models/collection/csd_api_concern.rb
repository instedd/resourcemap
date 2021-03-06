module Collection::CSDApiConcern
  extend ActiveSupport::Concern

  def csd_facility_entity_id
    identifier_fields.find(&:csd_facility_entity_id?)
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
    text_fields.select{|f| f.csd_address?(Field::CSDApiConcern::csd_facility_tag)}.group_by{|f| f.metadata_value_for("CSDCode") }
  end

  def csd_text_contact_points
    csd_contact_points_in text_fields
  end

  def csd_select_one_contact_points
    csd_contact_points_in select_one_fields
  end

  def csd_languages
    select_one_fields.select{|f| f.csd_language?(Field::CSDApiConcern::csd_facility_tag)}
  end

  def csd_status
    yes_no_fields.find(&:csd_status?)
  end

  def csd_other_ids
    identifier_fields.select(&:csd_other_id?)
  end

  def csd_contacts
    fields.select(&:csd_contact?)
          .group_by{|field| field.metadata_value_for("CSDCode")}
          .map{|contact| CSDContactMapping.new(contact[0], contact[1])}
  end

  def csd_organizations
    fields.select(&:csd_organization?)
          .group_by{|field| field.csd_organization_element}
          .map{|org| CSDOrganizationMapping.new(org[0], org[1])}
  end

  def csd_operating_hours
    fields.select{|f| f.csd_operating_hours?(Field::CSDApiConcern::csd_facility_tag)}
          .group_by{|f| f.csd_operating_hours_element}
          .map{|g| CSDOperatingHoursMapping.new(g[0], g[1])}
  end

  private

  def csd_contact_points_in(fields)
    fields.select(&:csd_contact_point?).group_by {|f| f.metadata_value_for("CSDCode") }
  end
end
