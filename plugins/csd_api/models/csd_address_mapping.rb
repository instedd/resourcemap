class CSDAddressMapping
	attr_reader :address_code
	attr_reader :address_lines

	def initialize(address_code, address_fields)
		@address_code = address_code
		@address_lines = address_fields.select(&:csd_address_line?).map{|f| CSDAddressLineMapping.new(f)}
	end
end