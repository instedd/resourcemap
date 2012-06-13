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
end
