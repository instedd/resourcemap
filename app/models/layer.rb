class Layer < ActiveRecord::Base
  belongs_to :collection
  has_many :fields

  accepts_nested_attributes_for :fields
end
