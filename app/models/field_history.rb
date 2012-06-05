class FieldHistory < ActiveRecord::Base
  belongs_to :field

  serialize :config
end
