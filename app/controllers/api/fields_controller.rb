class Api::FieldsController < ApiController
  before_filter :authenticate_api_user!

  expose(:layer)
  expose(:collection)

  def index
    render_json collection.visible_layers_for(current_user)
  end

  def mapping
    render_json collection.fields.map{|f| {name: f.name, id: f.id, code: f.code, kind: f.kind}}
  end

  def create
  	# Only users who can change this layer's structure are allowed to 
  	# create fields on it
  	authorize! :update, layer

  	# Necessary so that Activity logging works. Sth smells...
  	layer.user = current_user

  	# For now we won't allow API clients to specify fields' order
  	starting_ord = layer.next_field_ord

  	# * We explicitly enforce structure of fields to be created, to avoid
  	# accidental or malicious updates. 
  	# * We aren't supporting custom field config or metadata, for this is 
  	# an initial implementation and supporting those involves a lot of 
  	# validations. 
  	# * We must define a collection_id for field collection-wise 
  	# uniqueness constraints to work. Maybe it's due to a bug in the 
  	# Rails or ActiveRecord versions we use.
  	new_fields = params[:fields].each_with_index.map do |input_field, i|
  		{ 
  			name: input_field["name"], 
  			code: input_field["code"], 
  			kind: input_field["kind"],
  			ord: starting_ord + i,
  			collection_id: collection.id
  		}
		end

  	layer.fields.build new_fields

  	if layer.valid?
  		layer.save!
  		render_json :ok
  	else
  		render_error_response_409
  	end
  end
end
