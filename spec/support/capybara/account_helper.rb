module Capybara::AccountHelper

  def login_form
    "form#new_user"
  end

  def new_user
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
  end

  def last_email
    ActionMailer::Base.deliveries.last
  end

  def get_confirmation_token
    last_email.body.match(/confirmation_token=\w*/)
  end

  def notice_div
    'div.flash_notice'
  end

end
