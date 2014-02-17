class OrganizationMapping
	attr_reader :oid
	attr_reader :coded_type_fields
	attr_reader :addresses
	attr_reader :contacts
	attr_reader :languages
	attr_reader :contact_point_fields_by_type
	attr_reader :coded_type_for_contact_point_fields_by_type

	def initialize(collection)
		fields = collection.fields

		@oid = fields.find{|f| f.csd_oid?(Field::CSDApiConcern::csd_organization_tag)}
		@coded_type_fields = collection.select_one_fields.select(&:csd_coded_type?)
		@addresses = fields.select{|f| f.csd_address?(Field::CSDApiConcern::csd_organization_tag)}
												.group_by{|f| f.csd_address_element}
												.map{|address| CSDAddressMapping.new(address[0], address[1])}

		@contacts = fields.select(&:csd_contact?)
		          .group_by{|field| field.metadata_value_for("CSDCode")}
		          .map{|contact| CSDContactMapping.new(contact[0], contact[1])}

		@languages = fields.select{|f| f.csd_language?(Field::CSDApiConcern::csd_organization_tag)}
												.map{|f| CSDLanguageMapping.new(f)}

    @contact_point_fields_by_type = collection.csd_text_contact_points
    @coded_type_for_contact_point_fields_by_type = collection.csd_select_one_contact_points
	end
end