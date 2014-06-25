class SiteHistory < ActiveRecord::Base
  belongs_to :site
  belongs_to :collection
  belongs_to :user

  serialize :properties, Hash

  def store_in(index_name)
    Site::IndexUtils.store self, site_id, index_name
  end

  def to_elastic_search
    Site::IndexUtils.to_elastic_search(self, site_id)
  end
end
