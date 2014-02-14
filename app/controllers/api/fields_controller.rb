class Api::FieldsController < ApplicationController
  before_filter :authenticate_user!

  def index
    render_json collection.visible_layers_for(current_user)
  end
end
