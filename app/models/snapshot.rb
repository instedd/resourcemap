class Snapshot < ActiveRecord::Base
  belongs_to :collection
  has_many :user_snapshots, dependent: :destroy

  validates_presence_of :name
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

  after_destroy :destroy_index

  def destroy_index
    index.delete
  end

  def index_name
    collection.index_name snapshot_id: id
  end

  def index
    Tire::Index.new index_name
  end

  def fields
    collection.field_histories.at_date(date)
  end

  def site_mapping
    Site::IndexUtils.site_mapping fields
  end
end
