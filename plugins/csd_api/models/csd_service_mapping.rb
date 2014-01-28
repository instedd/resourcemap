class CSDServiceMapping
	attr_reader :oid
	attr_reader :names

	def initialize(service, fields)
		@oid = fields.find{|f| f.csd_oid?(Field::CSDApiConcern::csd_service_tag)}
		@names = fields.select{|f| f.csd_name?(Field::CSDApiConcern::csd_service_tag)}
										.group_by(&:csd_name_element)
										.map{|g| CSDNameMapping.new(g[0], g[1])}
	end
end