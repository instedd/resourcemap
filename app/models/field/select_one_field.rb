class Field::SelectOneField < Field
  def value_type_description
    "option values"
  end

  def error_description_for_invalid_values
  	"don't match any existing option"
  end

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		return nil unless value.present?

		decode_option(value, use_codes_instead_of_es_codes)
	end

	def apply_format_save_validation(value, use_codes_instead_of_es_codes, collection)
		value.blank? ? nil : decode_option(value, use_codes_instead_of_es_codes)
	end

	def cache_for_read
		@cache_for_read = true
	end

	private

	def decode_option(value, use_codes_instead_of_es_codes)
		if @cache_for_read && !@options_by_code_or_label_in_cache
			prepare_cache_for_read
		end

    value_id = nil
		if use_codes_instead_of_es_codes
			if @cache_for_read
				value_id = @options_by_code_or_label_in_cache[value.to_s]
			else
				config['options'].each do |option|
			  	value_id = option['id'] if option['label'] == value || option['code'] == value
				end
			end
		else
			if @cache_for_read
				value_id = @options_by_id_in_cache[value.to_s]
			else
				config['options'].each do |option|
			  	value_id = option['id'] if option['id'].to_s == value.to_s
				end
			end
		end
    raise "Invalid option in field #{code}" if value_id.nil?
    value_id
  end

  def prepare_cache_for_read
		@options_by_code_or_label_in_cache = {}
		@options_by_id_in_cache = {}

		config['options'].each do |option|
			@options_by_code_or_label_in_cache[option['code'].to_s] = option['id']
			@options_by_code_or_label_in_cache[option['label'].to_s] = option['id']
			@options_by_id_in_cache[option['id'].to_s] = option['id']
		end
	end

end