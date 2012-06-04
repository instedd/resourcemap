class SiteHistory < ActiveRecord::Base
  belongs_to :site

  serialize :properties, Hash

end