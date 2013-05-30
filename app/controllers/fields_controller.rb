class FieldsController < ApplicationController
	before_filter :setup_guest_user, :if => Proc.new { collection && collection.public }
  before_filter :authenticate_user!, :unless => Proc.new { collection && collection.public }

  def index
    if current_snapshot
      render json: collection.visible_layers_for(current_user, snapshot_id: current_snapshot.id)
    else
      render json: collection.visible_layers_for(current_user)
    end
  end
end
