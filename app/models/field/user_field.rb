class Field::UserField < Field
  def value_type_description
    "email addresses"
  end

  def error_description_for_invalid_values(exception)
    "don't match any email address of a member of this collection"
  end

  def valid_value?(user_email, site=nil)
    check_user_exists(user_email)
  end

	private

	def check_user_exists(user_email)
    user_emails = collection.users.map {|u| u.email}

    if !user_emails.include? user_email
      raise "Non-existent user email address in field #{code}"
    end
    true
  end
end
