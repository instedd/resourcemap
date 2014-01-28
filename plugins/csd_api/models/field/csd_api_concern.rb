module Field::CSDApiConcern
  extend ActiveSupport::Concern

  def csd_coded_type!(coding_schema)
  	put_in_metadata "CSDType", "codedType"
  	put_in_metadata "codingSchema", coding_schema
  	save!
  	self
  end

  def csd_facility_oid!
  	put_in_metadata "CSDType", "facilityOid"
  	save!
  	self
  end

  def csd_oid!(for_element)
    put_in_metadata "CSDAttributeFor", for_element
    put_in_metadata "CSDAttribute", "oid"
    save!
    self
  end

  def csd_contact(contact_code)
    put_in_metadata "CSDType", "contact"
    put_in_metadata "CSDCode", contact_code
    self
  end

  def csd_contact!(contact_code)
    csd_contact(contact_code)
    save!
    self
  end

  def csd_name(name_code, parent_tag)
    put_in_metadata Field::CSDApiConcern::csd_name_tag, name_code
    put_in_metadata "CSDChildOf", parent_tag
    self
  end

  def csd_name!(name_code, parent_tag)
    csd_name(name_code, parent_tag)
    save!
    self
  end

  def csd_common_name!(language)
    put_in_metadata Field::CSDApiConcern::csd_common_name_tag, "commonName"
    put_in_metadata "language", language
    save!
    self
  end

  def csd_forename!
    put_in_metadata Field::CSDApiConcern::csd_forename_tag, ''
    save!
    self
  end

  def csd_surname!
    put_in_metadata Field::CSDApiConcern::csd_surname_tag, ""
    save!
    self
  end

  def csd_address(address_code, parent_tag)
    put_in_metadata Field::CSDApiConcern::csd_address_tag, address_code
    put_in_metadata "CSDChildOf", parent_tag
    self
  end

  def csd_address!(address_code, parent_tag)
    csd_address(address_code, parent_tag)
    save!
    self
  end

  def csd_address_line!(component)
    put_in_metadata Field::CSDApiConcern::csd_address_line_tag, component
    save!
    self
  end

  def csd_language!(coding_schema, parent_tag)
    put_in_metadata Field::CSDApiConcern::csd_language_tag, ""
    put_in_metadata "CSDChildOf", parent_tag
    put_in_metadata "codingSchema", coding_schema
    save!
    self
  end

  def csd_organization(organization)
    put_in_metadata Field::CSDApiConcern::csd_organization_tag, organization
    self
  end

  def csd_organization!(organization)
    csd_organization(organization).save!
    self
  end

  def csd_service(service)
    put_in_metadata Field::CSDApiConcern::csd_service_tag, service
    self
  end

  def csd_service!(service)
    csd_service(service).save!
    self
  end

  def csd_operating_hours(oh_code, parent_tag)
    put_in_metadata Field::CSDApiConcern::csd_operating_hours_tag, oh_code
    put_in_metadata "CSDChildOf", parent_tag
    self
  end

  def csd_operating_hours!(oh_code, parent_tag)
    csd_operating_hours(oh_code, parent_tag)
    save!
    self
  end

  def csd_open_flag
    put_in_metadata Field::CSDApiConcern::csd_open_flag_tag, ''
    self
  end

  def csd_open_flag!
    csd_open_flag
    save!
    self
  end

  def csd_day_of_the_week
    put_in_metadata Field::CSDApiConcern::csd_day_of_the_week_tag, ''
    self
  end

  def csd_day_of_the_week!
    csd_day_of_the_week
    save!
    self
  end

  def csd_beginning_hour
    put_in_metadata Field::CSDApiConcern::csd_beginning_hour_tag, ''
    self
  end

  def csd_beginning_hour!
    csd_beginning_hour
    save!
    self
  end

  def csd_ending_hour
    put_in_metadata Field::CSDApiConcern::csd_ending_hour_tag, ''
    self
  end

  def csd_ending_hour!
    csd_ending_hour
    save!
    self
  end

  def csd_begin_effective_date
    put_in_metadata Field::CSDApiConcern::csd_begin_effective_date_tag, ''
    self
  end

  def csd_begin_effective_date!
    csd_begin_effective_date
    save!
    self
  end

  def csd_status?
  	csd_declared_type? "status"
  end

  def csd_language?(parent_tag)
    in_metadata?(Field::CSDApiConcern::csd_language_tag) &&
    metadata_value_for("CSDChildOf") == parent_tag
  end

  def csd_contact_point?
  	csd_declared_type? "contactPoint"
  end

  def csd_address?(parent_tag)
    in_metadata?(Field::CSDApiConcern::csd_address_tag) &&
    metadata_value_for("CSDChildOf") == parent_tag
  end

  def csd_other_name?
  	csd_declared_type? "otherName"
  end

  def csd_facility_type?
  	csd_declared_type?("facilityType") && in_metadata?("OptionList")
  end

  def csd_coded_type?
  	csd_declared_type?("codedType") && in_metadata?("codingSchema")
  end

  def csd_facility_oid?
  	csd_declared_type? "facilityOid" 
  end

  def csd_oid?(for_element)
    metadata_value_for("CSDAttributeFor") == for_element &&
    metadata_value_for("CSDAttribute") == "oid"
  end

  def csd_other_id?
    self.is_a?(Field::IdentifierField) && !csd_facility_oid?
  end

  def csd_declared_type?(type)
  	!self.metadata.blank? && csd_type == type
  end

  def csd_contact?
    csd_declared_type?("contact") && in_metadata?("CSDCode")
  end

  def csd_operating_hours?(parent_tag)
    in_metadata?(Field::CSDApiConcern::csd_operating_hours_tag) &&
    metadata_value_for("CSDChildOf") == parent_tag
  end

  def csd_open_flag?
    in_metadata?(Field::CSDApiConcern::csd_open_flag_tag)
  end

  def csd_day_of_the_week?
    in_metadata?(Field::CSDApiConcern::csd_day_of_the_week_tag)
  end

  def csd_beginning_hour?
    in_metadata?(Field::CSDApiConcern::csd_beginning_hour_tag)
  end

  def csd_ending_hour?
    in_metadata?(Field::CSDApiConcern::csd_ending_hour_tag)
  end

  def csd_begin_effective_date?
    in_metadata?(Field::CSDApiConcern::csd_begin_effective_date_tag)
  end

  def csd_name?(parent_tag)
    in_metadata?(Field::CSDApiConcern::csd_name_tag) &&
    metadata_value_for("CSDChildOf") == parent_tag
  end

  def csd_common_name?
    in_metadata?(Field::CSDApiConcern::csd_common_name_tag) &&
    in_metadata?("language")
  end

  def csd_forename?
    in_metadata?(Field::CSDApiConcern::csd_forename_tag)
  end

  def csd_surname?
    in_metadata?(Field::CSDApiConcern::csd_surname_tag)
  end

  def csd_address_line?
    in_metadata?(Field::CSDApiConcern::csd_address_line_tag)
  end

  def csd_contact_address?
    in_metadata?("CSDContactAddress")
  end

  def csd_organization?
    in_metadata?(Field::CSDApiConcern::csd_organization_tag)
  end

  def csd_service?
    in_metadata?(Field::CSDApiConcern::csd_service_tag)
  end

  def csd_type
  	metadata_value_for "CSDType"
  end

  # CSD named elements
  def csd_organization_element
    metadata_value_for Field::CSDApiConcern::csd_organization_tag
  end

  def csd_service_element
    metadata_value_for Field::CSDApiConcern::csd_service_tag
  end

  def csd_name_element
    metadata_value_for Field::CSDApiConcern::csd_name_tag
  end

  def csd_address_element
    metadata_value_for Field::CSDApiConcern::csd_address_tag
  end

  def csd_operating_hours_element
    metadata_value_for Field::CSDApiConcern::csd_operating_hours_tag
  end

  # CSD Tag inventory, refactor so its accessed as CSDTags::organization, CSDTags::service, etc
  def self.csd_facility_tag
    "CSDFacility"
  end

  def self.csd_organization_tag
    "CSDOrganization"
  end

  def self.csd_service_tag
    "CSDService"
  end

  def self.csd_common_name_tag
    "CSDCommonName"
  end

  def self.csd_surname_tag
    "CSDSurname"
  end

  def self.csd_name_tag
    "CSDName"
  end

  def self.csd_forename_tag
    "CSDForename"
  end

  def self.csd_address_tag
    "CSDAddress"
  end

  def self.csd_address_line_tag
    "CSDAddressLine"
  end

  def self.csd_contact_tag
    "CSDContact"
  end

  def self.csd_language_tag
    "CSDLanguage"
  end

  def self.csd_operating_hours_tag
    "CSDOperatingHours"
  end

  def self.csd_open_flag_tag
    "CSDOpenFlag"
  end

  def self.csd_day_of_the_week_tag
    "CSDDayOfTheWeek"
  end

  def self.csd_beginning_hour_tag
    "CSDBeginningHour"
  end

  def self.csd_ending_hour_tag
    "CSDEndingHour"
  end

  def self.csd_begin_effective_date_tag
    "CSDBeginEffectiveDate"
  end

  #These methods should either:
  # A) go away once we change the data structure to represent metadata, or at least
	# B) move to Field::Field
  def metadata_value_for(metadata_key)
    if in_metadata?(metadata_key)
      metadata_entry = self.metadata.values.find{|element| element["key"] == metadata_key}
      metadata_entry["value"]
    end
  end

  def in_metadata?(metadata_key)
    self.metadata && !self.metadata.values.find{|element| element["key"] == metadata_key}.nil?
  end

 	#This method in particular is really weird due to the metadata representation we're using.
  #We really need to refactor that.
  def put_in_metadata(key, value)
  	self.metadata = {} if self.metadata.blank?

  	entry = self.metadata.find {|k,v| v[key]}
  	entry = ["#{self.metadata.keys.length}", {}] if !entry
  	self.metadata[entry[0]] = { "key" => key, "value" => value }
  end
end