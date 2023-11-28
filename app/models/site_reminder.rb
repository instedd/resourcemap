class SiteReminder < ApplicationRecord
  belongs_to :reminder
  belongs_to :site

  after_save :touch_collection_lifespan
  after_destroy :touch_collection_lifespan

  private

  def touch_collection_lifespan
    Telemetry::Lifespan.touch_collection self.site.try(:collection)
  end
end
