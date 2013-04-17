require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  get "/"
  login_as "mmuller+3000@manas.com.ar", "123456789"
  logout
  i_should_see "Signed out successfully."
end
