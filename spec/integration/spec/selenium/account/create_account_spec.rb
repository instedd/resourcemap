require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  get "/"
  email = unique('testingstg@gmail.com')
  create_account email, "123456789"
  i_should_see "A message with a confirmation link has been sent to your email address. Please open the link to activate your account."
  sleep 10
  mail_body = get_mail
  link = get_link mail_body
  sleep 10
  get link
  sleep 5
  i_should_see "Your account was successfully confirmed. You are now signed in."
end