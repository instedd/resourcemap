class Snapshot < ActiveRecord::Base
  belongs_to :collection
  has_many :user_snapshots, dependent: :destroy

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :collection_id

  after_create :create_index

  def create_index
    index = index()

    index_properties = { mappings: { site: site_mapping } }
    index_properties.merge!(Site::IndexUtils::DowncaseAnalyzer)
    index.create(index_properties)

    docs = collection.site_histories.at_date(date).map do |history|
      history.collection = collection
      history.to_elastic_search
    end
    docs.each_slice(200) do |docs_slice|
      index.import docs_slice
    end

    index.refresh
  end

  after_destroy :destroy_index

  def destroy_index
    index.delete
  end

  def recreate_index
    destroy_index
    create_index
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

  # Given some collections and a user, returns a Hash collection_id => snapshot_name.
  def self.names_for_collections_and_user(collections, user)
    info_for_collections_ids_and_user(collections.map(&:id), user, "name")
  end

  # Given some collections and a user, returns a Hash collection_id => snapshot_id.
  def self.ids_for_collections_ids_and_user(collections_ids, user)
    info_for_collections_ids_and_user(collections_ids, user, "id")
  end

  def self.info_for_collections_ids_and_user(collections_ids, user, field)
    collections_ids = collections_ids.map { |id| connection.quote(id) }.join ', '
    user_id = connection.quote(user.id)
    results = connection.execute("
      select c.id, s.#{field}
      from collections c, user_snapshots u, snapshots s
      where c.id = u.collection_id and u.snapshot_id = s.id
      and u.user_id = #{user_id}
      and c.id IN (#{collections_ids})")
    Hash[results.to_a]
  end
end
