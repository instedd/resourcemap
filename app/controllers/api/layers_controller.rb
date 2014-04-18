class Api::LayersController < ApiController

  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_api_user!
  around_filter :rescue_with_check_api_docs

  # We removed the public attribute from layers, but we'll accept requests sending it
  # so we don't break compatibility with already running clients.
  before_filter :ignore_public_attribute

  def index
    render_json collection.layers_to_json(current_user_snapshot.at_present?, current_user)
  end
end
