class FieldHistory < ActiveRecord::Base
  include Field::Base
  include Field::TireConcern

  belongs_to :field
  belongs_to :collection
  belongs_to :layer

  serialize :config
  serialize :metadata

  def es_code
    field_id.to_s
  end

  def cache_for_read
    field.cache_for_read
  end

  def api_value(value)
    field.api_value(value)
  end

  def human_value(value)
    field.human_value(value)
  end

  def as_json(options = {})
    { code: code, collection_id: collection_id, config: config, id: field_id, kind: kind, layer_id: layer_id, name: name, ord: ord}
  end
end
