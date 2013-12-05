class SiteHistory < ActiveRecord::Base
  belongs_to :site
  belongs_to :collection
  belongs_to :user

  serialize :properties, Hash

  def store_in(index)
    Site::IndexUtils.store self, site_id, index
  end

  def to_elastic_search
    Site::IndexUtils.to_elastic_search(self, id)
  end
end
