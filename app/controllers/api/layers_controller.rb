class Api::LayersController < ApplicationController

  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_api_user!
  around_filter :rescue_with_check_api_docs

  def index
    render_json collection.layers_to_json(current_user_snapshot.at_present?, current_user)
  end
end
