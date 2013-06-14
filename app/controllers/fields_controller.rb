class FieldsController < ApplicationController
  before_filter :authenticate_user!

  def index
    options = {}
    options[:snapshot_id] = current_snapshot.id if current_snapshot
    render json: collection.visible_layers_for(current_user, options)
  end
end
