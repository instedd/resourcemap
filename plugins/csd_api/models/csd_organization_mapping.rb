class CSDOrganizationMapping
	attr_reader :oid
	attr_reader :services

	def initialize(organization, fields)
		@oid = fields.find {|f| f.csd_oid?(Field::CSDApiConcern::csd_organization_tag)}
		@services = fields.select(&:csd_service?)
											.group_by(&:csd_service_element)
											.map{|service| CSDServiceMapping.new(service[0], service[1])}
	end
end