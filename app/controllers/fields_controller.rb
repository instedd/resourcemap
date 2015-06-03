class FieldsController < ApplicationController
  before_filter :authenticate_api_user!, :unless => Proc.new { collection && collection.anonymous_name_permission == 'read' && (params[:action] == "index" || params[:action] == "show") }
  before_filter :authenticate_collection_admin!, except: :index

  expose(:field) { fields.find params[:id] }

  def index
    options = {}
    options[:snapshot_id] = current_user_snapshot.snapshot.id if !current_user_snapshot.at_present?
    render_json collection.visible_layers_for(current_user, options)
  end

  def show
    render_json field
  end

  def hierarchy
    field.cache_for_read
    if !field.hierarchy?
      render_json({message: invalid_hiearchy_message("The field '#{field.code}' is not a hierarchy")}, status: 422)
    elsif value = params[:under]
      begin
        descendants = field.descendants_of_in_hierarchy(value)
        if node = params[:node]
          field.valid_value?(node)
          render_json descendants.include?(node)
        else
          render_json descendants
        end
      rescue => ex
        render_json({message: invalid_hiearchy_message(ex.message)}, status: 422)
      end
    elsif ((node = params[:node]) && (type = params[:type]))
      render_json field.ascendants_with_type(node, type)
    else
      respond_to do |format|
        format.json { render_json field }
        format.csv { send_data field.hierarchy_to_csv, type: 'text/csv', filename: "hierarchy_#{field.code}.csv"}
      end
    end
  end

  # Should be removed?
  def mapping
    render_json collection.fields.map{|f| {name: f.name, id: f.id, code: f.code, kind: f.kind}}
  end

  private

  def invalid_hiearchy_message(custom_error)
    "#{custom_error}. Usage: The field_id should correspond to a hierarchy field. Use parameter 'under' to query nodes under a certain one. Use also parameter 'node' to ask if this node is under the one in the parameter 'under'."
  end
end
