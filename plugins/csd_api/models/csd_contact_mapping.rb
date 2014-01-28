class CSDContactMapping
	attr_reader :contact
	attr_reader :all_components

	attr_reader :names
	attr_reader :addresses

	def initialize(contact_code, fields)
		@contact = contact_code
		@all_components = fields

		@names = fields.select{|f| f.csd_name?(Field::CSDApiConcern::csd_contact_tag)}
										.group_by{|f| f.csd_name_element}
										.map{|name| CSDNameMapping.new(name[0], name[1])}

		@addresses = fields.select{|f| f.csd_address?(Field::CSDApiConcern::csd_contact_tag)}
												.group_by{|f| f.csd_address_element}
												.map{|address| CSDAddressMapping.new(address[0], address[1])}
	end
end