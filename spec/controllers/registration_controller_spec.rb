require 'spec_helper'

describe RegistrationsController, :type => :controller do
  include Devise::Test::ControllerHelpers
  render_views

  before :each do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  let!(:user) { User.make email: 'foo@bar.com.ar', password: 'secret'}

  it "should respond with 200 for valid user credentials" do
    get :validate_credentials, params: { user: 'foo@bar.com.ar', password: 'secret' }
    expect(response).to be_success
    json = JSON.parse response.body
    expect(json["message"]).to eq('Valid credentials')
  end

  it "should respond with 422 for user not found" do
    get :validate_credentials, params: { user: 'inexistent@mail.com', password: 'secret' }
    expect(response.status).to eq(422)
    json = JSON.parse response.body
    expect(json["message"]).to eq('Invalid credentials')
  end

  it "should respond with 422 for invlid password" do
    get :validate_credentials, params: { user: 'foo@bar.com.ar', password: 'invalid' }
    expect(response.status).to eq(422)
    json = JSON.parse response.body
    expect(json["message"]).to eq('Invalid credentials')
  end
end
