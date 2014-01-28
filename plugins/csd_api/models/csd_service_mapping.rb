class CSDServiceMapping
	attr_reader :oid

	def initialize(service, fields)
		@oid = fields.find{|f| f.csd_oid?(Field::CSDApiConcern::csd_service_tag)}
	end
end