class Layer < ActiveRecord::Base
  belongs_to :collection
  has_many :fields, dependent: :destroy

  accepts_nested_attributes_for :fields

  after_save :update_collection_mapping
  def update_collection_mapping
    collection.update_mapping
  end
end
