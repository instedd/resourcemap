class Snapshot < ActiveRecord::Base
  belongs_to :collection
  has_many :user_snapshots, dependent: :destroy

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :collection_id

  after_create :create_index

  after_save :touch_collection_lifespan
  after_destroy :touch_collection_lifespan

  def create_index
    index_properties = {
      mappings: { site: site_mapping }
    }
    index_properties.merge!(Site::IndexUtils::DefaultIndexSettings)

    client = Elasticsearch::Client.new
    client.indices.create index: index_name, body: index_properties

    docs = collection.site_histories.at_date(date).map do |history|
      history.collection = collection
      history.to_elastic_search
    end
    docs.each_slice(200) do |docs_slice|
      ops = []
      docs_slice.each do |doc|
        ops.push index: { _index: index_name, _type: 'site', _id: doc[:id]}
        ops.push doc
      end
      client.bulk body: ops
    end
    client.indices.refresh
  end

  after_destroy :destroy_index

  def destroy_index
    Elasticsearch::Client.new.indices.delete index: index_name
  end

  def recreate_index
    destroy_index rescue nil
    create_index
  end

  def index_name
    collection.index_name snapshot_id: id
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

    return {} unless collections_ids.length > 0

    results = connection.execute("
      select c.id, s.#{field}
      from collections c, user_snapshots u, snapshots s
      where c.id = u.collection_id and u.snapshot_id = s.id
      and u.user_id = #{user_id}
      and c.id IN (#{collections_ids})")
    Hash[results.to_a]
  end
end
