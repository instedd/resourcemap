module Capybara::AccountHelper

  def login_form
    "form#new_user"
  end

  def new_user
    User.make!(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
  end

  def last_email
    ActionMailer::Base.deliveries.last
  end

  def get_confirmation_token
    # Confirmation tokens are generated using SecureRandom.urlsafe_base64 and
    # they can contain dashes and underscores
    last_email.body.match(/confirmation_token=[0-9a-zA-Z_-]*/)
  end

  def notice_div
    'div.flash_notice'
  end

end
