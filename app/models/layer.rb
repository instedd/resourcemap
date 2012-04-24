class Layer < ActiveRecord::Base
  belongs_to :collection
  has_many :fields, order: 'ord', dependent: :destroy

  accepts_nested_attributes_for :fields

  validates_presence_of :ord

  after_save :update_collection_mapping
  def update_collection_mapping
    collection.update_mapping
  end

  # Returns the next ord value for a field that is going to be created
  def next_field_ord
    field = fields.select('max(ord) as o').first
    field ? field['o'].to_i + 1 : 1
  end
end
