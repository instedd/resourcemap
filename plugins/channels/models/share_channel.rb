class ShareChannel < ActiveRecord::Base
  belongs_to :channel
  belongs_to :collection

  after_save :touch_collection_lifespan
  after_destroy :touch_collection_lifespan
end
