require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  get '/'
  login_as "mmul+1@manas.com.ar", "12345678"
  i_should_see "Invalid email or password."
end
