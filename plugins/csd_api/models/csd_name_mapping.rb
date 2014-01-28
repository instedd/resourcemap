class CSDNameMapping
	attr_reader :name
	attr_reader :all_components
	attr_reader :forename
	attr_reader :surname
	attr_reader :common_names

	def initialize(name, fields)
		@name = name
		@all_components = fields

		@forename = fields.find(&:csd_forename?)
		@surname = fields.find(&:csd_surname?)
		@common_names = fields.select(&:csd_common_name?).map{|f| CSDCommonNameMapping.new(f)}
	end

	def honorific
	end

	def other_names
	end

	def suffix
	end
end