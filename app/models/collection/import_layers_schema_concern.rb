module Collection::ImportLayersSchemaConcern

	def import_schema(layers_string, user)
		layers_json = JSON.parse layers_string
		layers_json.each do |layer_json|
			params = layer_json.except(*["created_at", "updated_at", "fields"])
			layer = layers.new params
			layer.user = user
			if layer_json["fields"]
				layer_json["fields"].each do |field_json|
					field_params = field_json.except(*["created_at", "updated_at", "collection_id"])
					field = layer.fields.new field_params
					field.collection_id = self.id
				end
			end
			layer.save!
		end
	end
end