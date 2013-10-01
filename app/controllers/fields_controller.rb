class FieldsController < ApplicationController
	before_filter :setup_guest_user, :if => Proc.new { collection && collection.public }
  before_filter :authenticate_user!, :unless => Proc.new { collection && collection.public }
  before_filter :authenticate_collection_admin!, except: :index

  expose(:field) { fields.find params[:id] }

  def index
    options = {}
    options[:snapshot_id] = current_user_snapshot.snapshot.id if !current_user_snapshot.at_present?
    render json: collection.visible_layers_for(current_user, options)
  end

  def show
    render json: field.to_json
  end

  def hierarchy
    if !field.hierarchy?
      render json: {message: invalid_hiearchy_message("The field '#{field.code}' is not a hierarchy")}, status: 422
    elsif value = params[:under]
      begin
        descendants = field.descendants_of_in_hierarchy(value, false)
        if node = params[:node]
          field.valid_value?(node)
          render json: descendants.include?(node)
        else
          render json: descendants
        end
      rescue => ex
        render json: {message: invalid_hiearchy_message(ex.message)}, status: 422
      end
    else
      render json: field.to_json
    end
  end

  def mapping
    render json: collection.fields.map{|f| {name: f.name, id: f.id, code: f.code, kind: f.kind}}.to_json
  end

  private

  def invalid_hiearchy_message(custom_error)
    "#{custom_error}. Usage: The field_id should correspond to a hierarchy field. Use parameter 'under' to query nodes under a certain one. Use also parameter 'node' to ask if this node is under the one in the parameter 'under'."
  end
end
