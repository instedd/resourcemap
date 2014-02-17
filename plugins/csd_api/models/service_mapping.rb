class ServiceMapping
	attr_reader :oid
	attr_reader :coded_type_fields
	attr_reader :status

	def initialize(collection)
		fields = collection.fields.all

		@oid = fields.find{|f| f.csd_oid?(Field::CSDApiConcern::csd_service_tag)}
		@coded_type_fields = collection.select_one_fields.select(&:csd_coded_type?)
		@status = collection.select_one_fields.find(&:csd_status?)
	end
end