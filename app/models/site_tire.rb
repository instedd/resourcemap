module SiteTire
  extend ActiveSupport::Concern

  included do
    after_save :store_in_index
    after_destroy :remove_from_index
    delegate :index_name, :index, :to => :collection
  end

  def store_in_index
    index.store :id => id, :type => :site, :location => {:lat => lat, :lon => lng}, :properties => properties
    index.refresh
  end

  def remove_from_index
    index.remove :id => id, :type => :site
    index.refresh
  end
end
