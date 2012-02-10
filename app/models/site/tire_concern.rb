module Site::TireConcern
  extend ActiveSupport::Concern

  included do
    after_save :store_in_index, :unless => :group?
    after_destroy :remove_from_index, :unless => :group?

    delegate :index_name, :index, :to => :collection
  end

  def store_in_index
    index.store({
      :id => id,
      :type => :site,
      :location => {:lat => lat.to_f, :lon => lng.to_f},
      :properties => properties,
      :parent_ids => hierarchy ? hierarchy.split(',').map(&:to_i) : nil
    })
    index.refresh
  end

  def remove_from_index
    index.remove :id => id, :type => :site
    index.refresh
  end
end
