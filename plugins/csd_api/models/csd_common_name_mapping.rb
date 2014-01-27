class CSDCommonNameMapping
	attr_reader :field
	attr_reader :language

	def initialize(field)
		@field = field
		@language = field.metadata_value_for "language"
	end
end