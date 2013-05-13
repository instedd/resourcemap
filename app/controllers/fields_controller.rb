class FieldsController < ApplicationController
	before_filter :setup_guest_user, :except => :search, :if => Proc.new { collection.public }
  before_filter :authenticate_user!, :except => :index, :unless => Proc.new { collection.public }

  def index
    if current_snapshot
      render json: collection.visible_layers_for(current_user, snapshot_id: current_snapshot.id)
    else
      render json: collection.visible_layers_for(current_user)
    end
  end
end
