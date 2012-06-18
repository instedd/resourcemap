class MembersController < ApplicationController
  before_filter :authenticate_user!
  def index
    render json: collection.users.all.to_json
  end
end
