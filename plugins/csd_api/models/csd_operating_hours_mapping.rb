class CSDOperatingHoursMapping
	attr_reader :open_flag

	def initialize(oh, fields)
		@open_flag = fields.find(&:csd_open_flag?)
	end
end