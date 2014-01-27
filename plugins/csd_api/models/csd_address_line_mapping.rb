class CSDAddressLineMapping
	attr_reader :field
	attr_reader :component

	def initialize(field)
		@field = field
		@component = field.metadata_value_for "CSDContactAddressLine"
	end
end