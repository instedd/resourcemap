class Snapshot < ActiveRecord::Base
  belongs_to :collection

  validates_uniqueness_of :name, :scope => :collection_id

  after_create :create_index
  def create_index
    index = Tire::Index.new index_name
    index.create mappings: { site: site_mapping }

    collection.site_histories.at_date(date).each do |history|
      history.store_in index
    end

    index.refresh
  end

  def index_name
    collection.index_name snapshot: name
  end

  def index
    Tire::Index.new index_name
  end

  def site_mapping
    Site::IndexUtils.site_mapping collection.field_histories.at_date(date).all
  end
end
