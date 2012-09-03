class FieldHistory < ActiveRecord::Base
  include Field::Base
  include Field::TireConcern

  belongs_to :field
  belongs_to :collection
  belongs_to :layer

  serialize :config

  def es_code
    field_id.to_s
  end

  def as_json(options = {})
    { code: code, collection_id: collection_id, config: config, id: field_id, kind: kind, layer_id: layer_id, name: name, ord: ord}
  end
end
