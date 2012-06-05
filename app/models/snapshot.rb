class Snapshot < ActiveRecord::Base
  belongs_to :collection

  validates_uniqueness_of :name, :scope => :collection_id
end
