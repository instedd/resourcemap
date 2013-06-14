class FieldsController < ApplicationController
  before_filter :authenticate_user!

  def index
    options = {}
    options[:snapshot_id] = current_user_snapshot.snapshot.id if !current_user_snapshot.at_present?
    render json: collection.visible_layers_for(current_user, options)
  end
end
