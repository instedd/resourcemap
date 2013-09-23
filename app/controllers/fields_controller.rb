class FieldsController < ApplicationController
	before_filter :setup_guest_user, :if => Proc.new { collection && collection.public }
  before_filter :authenticate_user!, :unless => Proc.new { collection && collection.public }
  before_filter :authenticate_collection_admin!, only: [:show, :mapping]

  expose(:field) { fields.find params[:id] }

  def index
    options = {}
    options[:snapshot_id] = current_user_snapshot.snapshot.id if !current_user_snapshot.at_present?
    render json: collection.visible_layers_for(current_user, options)
  end

  def show
    render json: field.to_json
  end

  def mapping
    render json: collection.fields.map{|f| {name: f.name, id: f.id, code: f.code, kind: f.kind}}.to_json
  end
end
