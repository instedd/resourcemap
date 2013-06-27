class Field::UserField < Field
  def value_type_description
    "email addresses"
  end

  def error_description_for_invalid_values
    "don't match any email address of a member of this collection"
  end

  def apply_format_save_validation(value, use_codes_instead_of_es_codes, collection)
  	value.blank? ? nil : check_user_exists(value, collection)
	end

	private

	def check_user_exists(user_email, collection)
    user_emails = collection.users.map {|u| u.email}

    if !user_emails.include? user_email
      raise "Non-existent user email address in field #{code}"
    end
    user_email
  end
end