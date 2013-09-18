require 'spec_helper'

describe RegistrationsController do
  include Devise::TestHelpers
  render_views

  before :each do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  let!(:user) { User.make email: 'foo@bar.com.ar', password: 'secret'}

  it "should respond with 200 for valid user credentials" do
    get :validate_credentials, user: 'foo@bar.com.ar', password: 'secret'
    response.should be_success
    json = JSON.parse response.body
    json["message"].should eq('Valid credentials')
  end

  it "should respond with 422 for user not found" do
    get :validate_credentials, user: 'inexistent@mail.com', password: 'secret'
    response.status.should eq(422)
    json = JSON.parse response.body
    json["message"].should eq('Invalid credentials')
  end

  it "should respond with 422 for invlid password" do
    get :validate_credentials, user: 'foo@bar.com.ar', password: 'invalid'
    response.status.should eq(422)
    json = JSON.parse response.body
    json["message"].should eq('Invalid credentials')
  end
end
