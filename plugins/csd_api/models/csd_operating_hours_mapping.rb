class CSDOperatingHoursMapping
	attr_reader :open_flag
	attr_reader :day_of_the_week
	attr_reader :beginning_hour
	attr_reader :ending_hour
	attr_reader :begin_effective_date

	def initialize(oh, fields)
		@open_flag = fields.find(&:csd_open_flag?)
		@day_of_the_week = fields.find(&:csd_day_of_the_week?)
		@beginning_hour = fields.find(&:csd_beginning_hour?)
		@ending_hour = fields.find(&:csd_ending_hour?)
		@begin_effective_date = fields.find(&:csd_begin_effective_date?)
	end
end