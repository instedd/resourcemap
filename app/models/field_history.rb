class FieldHistory < ActiveRecord::Base
  belongs_to :field
  belongs_to :collection

  serialize :config
end
