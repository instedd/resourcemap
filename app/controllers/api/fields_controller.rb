class Api::FieldsController < ApplicationController
  before_filter :authenticate_api_user!

  def index
    render_json collection.visible_layers_for(current_user)
  end

  def mapping
    render_json collection.fields.map{|f| {name: f.name, id: f.id, code: f.code, kind: f.kind}}
  end

end
