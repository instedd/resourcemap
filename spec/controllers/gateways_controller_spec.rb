require 'spec_helper'

describe GatewaysController, :type => :controller do
  include Devise::Test::ControllerHelpers
  render_views

  let(:user) { User.make }
  let(:gateway) { user.channels.make name: 'default', basic_setup: true, ticket_code: '2222', is_enable: false }

  before(:each) {sign_in user}
  it "should turn on gateway" do
    post :status, params: { id: gateway.id, status: true, format: 'json' }
    expect(Channel.find(gateway.id).is_enable).to eq(true)
  end

  describe 'analytic' do
    it 'should changed user.gateway_count by 1' do
      expect {
        post :create, params: { gateway: { name: 'default1', basic_setup: true, ticket_code: '2222', is_enable: true, user_id: user.id } }
      }.to change{
        u = User.find user.id
        u.gateway_count
      }.from(0).to(1)
    end
  end
end
