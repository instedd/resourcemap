module Collection::ElasticsearchConcern
  extend ActiveSupport::Concern

  included do
    after_create :create_index
    after_destroy :destroy_index
  end

  def create_index
    index_properties = {
      refresh: true,
      mappings: { site: site_mapping },
    }
    index_properties.merge!(Site::IndexUtils::DowncaseAnalyzer)

    result = Elasticsearch::Client.new.indices.create index: index_name, body: index_properties

    unless result["acknowledged"]
      error = "Can't create index for collection #{name} (ID: #{id})."
      Rails.logger.error error
      Rails.logger.error "ElasticSearch response was: #{result}."
      raise error
    end

    # This is because in the tests collections are created and the
    # fields association will almost always be empty, but it needs to
    # be refreshed afte creating layers and fields.
    clear_association_cache if Rails.env.test?
  end

  def site_mapping
    Site::IndexUtils.site_mapping(fields)
  end

  def update_mapping
    client = Elasticsearch::Client.new
    client.indices.put_mapping index: index_name, type: 'site', body: {site: site_mapping}
    client.indices.refresh index: index_name
  end

  def recreate_index
    destroy_index
    create_index

    client = Elasticsearch::Client.new

    docs = sites.map do |site|
      site.collection = self
      site.to_elastic_search
    end
    docs.each_slice(1000) do |docs_slice|
      ops = []
      docs_slice.each do |doc|
        ops.push index: { _index: index_name, _type: 'site', _id: doc[:id]}
        ops.push doc
      end
      client.bulk body: ops
    end
    client.indices.refresh index: index_name
  end

  def destroy_index
    Elasticsearch::Client.new.indices.delete index: index_name
  end

  def index
    @index ||= self.class.index(id)
  end

  def index_name(options = {})
    self.class.index_name id, options
  end

  def new_search(options = {})
    Search.new(self, options)
  end

  def elasticsearch_count
    client = Elasticsearch::Client.new
    if block_given?
      value = client.count index: index_name, body: yield
    else
      value = client.count index: index_name
    end
    value["count"]
  end

  def new_map_search
    MapSearch.new id
  end

  def new_elasticsearch_search(options = {})
    self.class.new_elasticsearch_search(id, options)
  end

  module ClassMethods
    INDEX_NAME_PREFIX = Rails.env == 'test' ? "collection_test" : "collection"

    def index_name(id, options = {})
      if options[:snapshot_id]
        return "#{INDEX_NAME_PREFIX}_#{id}_#{options[:snapshot_id]}"
      end

      if options[:user]
        snapshot = Collection.find(id).snapshot_for(options[:user])
        if snapshot
          return "#{INDEX_NAME_PREFIX}_#{id}_#{snapshot.id}"
        end
      end

      "#{INDEX_NAME_PREFIX}_#{id}"
    end

    def index(id)
      ::Tire::Index.new index_name(id)
    end

    def new_elasticsearch_search(*ids, options)
      # If we want the indices for many collections for a given user, it's faster
      # to get all snapshots ids first instead of fetching them one by one for each collection.
      # This optimization does that.
      if options[:user] && !options[:snapshot_id]
        collection_ids_to_snapshot_id = Snapshot.ids_for_collections_ids_and_user(ids, options[:user])
        options.delete :user
      end

      index_names = ids.map do |id|
        if collection_ids_to_snapshot_id
          options[:snapshot_id] = collection_ids_to_snapshot_id[id.to_i]
        end

        index_name(id, options)
      end
      Tire::Search::Search.new index_names, type: :site
    end
  end
end
