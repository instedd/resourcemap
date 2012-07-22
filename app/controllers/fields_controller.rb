class FieldsController < ApplicationController
  before_filter :authenticate_user!

  def index
    if current_snapshot
      render json: collection.visible_fields_for(current_user, snapshot_id: current_snapshot.id)
    else
      render json: collection.visible_fields_for(current_user)
    end
  end
end
