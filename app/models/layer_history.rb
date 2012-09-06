class LayerHistory < ActiveRecord::Base
  belongs_to :layer
  belongs_to :collection

  has_many :field_histories, :foreign_key => "layer_id", :primary_key => "layer_id"

  def as_json(options = {})
    {collection_id: collection_id, id: layer_id, name: name, ord: ord, public: public, fields: field_histories.map {|f| f.as_json} }
  end


end