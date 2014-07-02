class FieldHistory < ActiveRecord::Base
  include Field::Base
  include Field::ElasticsearchConcern

  belongs_to :field
  belongs_to :collection
  belongs_to :layer

  serialize :config, MarshalZipSerializable
  serialize :metadata

  def es_code
    field_id.to_s
  end

  def cache_for_read
    safe_field.cache_for_read
  end

  def api_value(value)
    safe_field.api_value(value)
  end

  def human_value(value)
    safe_field.human_value(value)
  end

  def allow_decimals?
    safe_field.allow_decimals?
  end

  def safe_field
    field = field()
    return field if field

    @fake_field ||= Field.new attributes.except("id", "valid_since", "valid_to", "field_id", "version")
  end

  def as_json(options = {})
    { code: code, collection_id: collection_id, config: config, id: field_id, kind: kind, layer_id: layer_id, name: name, ord: ord}
  end
end
