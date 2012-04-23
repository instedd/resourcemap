class Field < ActiveRecord::Base
  include Field::TireConcern

  belongs_to :collection
  belongs_to :layer

  serialize :config

  before_save :set_collection_id_to_layer_id
  def set_collection_id_to_layer_id
    self.collection_id = layer.collection_id if layer
  end

  def select_kind?
    kind == 'select_one' || kind == 'select_many'
  end

  def non_empty_value
    kind == 'numeric' ? 1 : 'foo'
  end
end
