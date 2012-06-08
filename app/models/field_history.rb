class FieldHistory < ActiveRecord::Base
  include Field::Base
  include Field::TireConcern

  belongs_to :field
  belongs_to :collection

  serialize :config
end
