class LayerHistory < ActiveRecord::Base
  belongs_to :layer
  belongs_to :collection

end