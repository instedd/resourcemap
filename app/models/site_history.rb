class SiteHistory < ActiveRecord::Base
  belongs_to :site
  belongs_to :collection

  serialize :properties, Hash

  def store_in(index, options = {})
    Site::IndexUtils.store self, site_id, index, options
  end
end
