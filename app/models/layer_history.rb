class LayerHistory < ActiveRecord::Base
  belongs_to :layer
  belongs_to :collection

  #has_many :field_histories, :conditions => proc { {:field_histories => {layer_id: layer_id}} }

  has_many :field_histories, :through => :layer



end