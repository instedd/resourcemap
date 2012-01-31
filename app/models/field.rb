class Field < ActiveRecord::Base
  belongs_to :collection
  belongs_to :layer

  before_save :set_collection_id_to_layer_id
  def set_collection_id_to_layer_id
    self.collection_id = layer.id if layer
  end
end
