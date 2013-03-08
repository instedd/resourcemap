class Field::EmailField < Field

	def apply_format_update_validation(value, use_codes_instead_of_es_codes, collection)
		value.blank? ? nil : check_email_format(value)
	end

	private

	def check_email_format(value)
    regex = Regexp.new('^(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})$')
    if value.match(regex).nil?
      raise "Invalid email address in #{code} field"
    end
    value
  end

end