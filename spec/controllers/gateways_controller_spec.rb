require 'spec_helper'

describe GatewaysController do
  include Devise::TestHelpers
  render_views

  let!(:user) { User.make }
  let!(:gateway) { user.channels.make name: 'default', is_manual_configuration: false, ticket_code: '2222', is_enable: false }

  before(:each) {sign_in user}
  it "should turn on gateway" do 
    post :status, id: gateway.id, status: true, format: 'json' 
    Channel.find(gateway).is_enable.should == true
  end
end
