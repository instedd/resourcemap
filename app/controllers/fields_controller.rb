class FieldsController < ApplicationController
  before_filter :authenticate_user!

  def index
    render json: fields
  end
end
