module Capybara::AccountHelper

  def login_form
    "form#new_user"
  end

  def new_user
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
  end

end