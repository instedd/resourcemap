class CSDContactMapping
	attr_reader :contact
	attr_reader :all_components

	attr_reader :names
	attr_reader :addresses

	def initialize(contact_code, fields)
		@contact = contact_code
		@all_components = fields

		@names = fields.select(&:csd_contact_name?)
										.group_by{|f| f.metadata_value_for("CSDContactName")}
										.map{|name| CSDNameMapping.new(name[0], name[1])}

		@addresses = fields.select(&:csd_contact_address?)
												.group_by{|f| f.metadata_value_for("CSDContactAddress")}
												.map{|address| CSDAddressMapping.new(address[0], address[1])}
	end
end