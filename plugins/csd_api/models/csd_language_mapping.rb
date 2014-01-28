class CSDLanguageMapping
	attr_reader :field
	attr_reader :coding_schema

	def initialize(field)
		@field = field
		@coding_schema = field.metadata_value_for("codingSchema")
	end
end