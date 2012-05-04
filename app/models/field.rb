class Field < ActiveRecord::Base
  include Field::TireConcern

  belongs_to :collection
  belongs_to :layer

  validates_presence_of :ord

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

  # Returns the label for the given option code.
  # Returns the same code if the option is not found or this is not a
  # select_one or select_many field.
  def option_label(code)
    if config && config['options']
      config['options'].each do |option|
        return option['label'] if option['code'] == code
      end
    end

    return code
  end
end
