class GatewaysController < ApplicationController
  before_filter :authenticate_user!
  def index
    current_user.memberships.find_all_by_admin true
  end
end
