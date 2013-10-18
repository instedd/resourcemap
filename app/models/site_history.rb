class SiteHistory < ActiveRecord::Base
  belongs_to :site
  belongs_to :collection
  belongs_to :user

  serialize :properties, Hash

  def store_in(index)
    Site::IndexUtils.store self, site_id, index
  end
end
