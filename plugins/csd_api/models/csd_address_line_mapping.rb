class CSDAddressLineMapping
	attr_reader :field
	attr_reader :component

	def initialize(field)
		@field = field
		@component = field.metadata_value_for(Field::CSDApiConcern::csd_address_line_tag)
	end
end