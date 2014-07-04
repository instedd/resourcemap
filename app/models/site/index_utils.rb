module Site::IndexUtils
  extend self

  DateFormat = "%Y%m%dT%H%M%S.%L%z"
  DowncaseAnalyzer = {
    settings: {
      index: {
        analysis: {
          analyzer: {
            downcase: {
              tokenizer: :keyword,
              filter: :lowercase,
              type: :custom,
            }
          }
        }
      }
    }
  }

  class DefaultStrategy
    def self.store(document, index_name, options = {})
      client = Elasticsearch::Client.new
      result = client.index index: index_name, type: 'site', id: document[:id], body: document
      if result['error']
        raise "Can't store site in index: #{result['error']}"
      end

      unless options[:refresh] == false
        client.indices.refresh index: index_name
      end
    end
  end

  class BulkStrategy
    def initialize
      @documents = []
      @client = Elasticsearch::Client.new
    end

    def store(document, index_name, options = {})
      @documents.push index: { _index: index_name, _type: 'site', _id: document[:id]}
      @documents.push document

      flush if @documents.length >= 2000
    end

    def flush
      @client.bulk body: @documents
      @documents.clear
    end
  end

  def self.strategy
    Thread.current[:index_utils_strategy] || DefaultStrategy
  end

  def self.strategy=(strategy)
    Thread.current[:index_utils_strategy] = strategy
  end

  def self.bulk
    self.strategy = BulkStrategy.new
    yield
  ensure
    self.strategy.flush
    self.strategy = nil
  end

  def store(site, site_id, index_name, options = {})
    document = to_elastic_search(site, site_id)
    Site::IndexUtils.strategy.store(document, index_name, options)
  end

  def to_elastic_search(site, site_id)
    hash = {
      id: site_id,
      name: site.name,
      id_with_prefix: site.id_with_prefix,
      uuid: site.uuid,
      type: :site,
      properties: site.properties,
      created_at: site.created_at.utc.strftime(DateFormat),
      updated_at: site.updated_at.utc.strftime(DateFormat),
      icon: site.collection.icon,
      # If the migration to add the version in Sites is not runned, then calling site.version will cause some previous migration to fail
      version: (site.version rescue nil)
    }

    if site.lat? && site.lng?
      hash[:location] = {lat: site.lat.to_f, lon: site.lng.to_f}
      hash[:lat_analyzed] = site.lat.to_s
      hash[:lng_analyzed] = site.lng.to_s
    end
    hash.merge! site.extended_properties if site.is_a? Site
    hash
  end

  def site_mapping(fields)
    {
      properties: {
        name: {
          type: :multi_field,
          fields: {
            name: { type: :string },
            downcase: { type: :string, index: :analyzed, analyzer: :downcase },
          },
        },
        id_with_prefix: { type: :string },
        uuid: { type: :string, index: :not_analyzed },
        location: { type: :geo_point },
        lat_analyzed: { type: :string },
        lng_analyzed: { type: :string },
        created_at: { type: :date, format: :basic_date_time },
        updated_at: { type: :date, format: :basic_date_time },
        properties: { properties: fields_mapping(fields) },
        version: { type: :long }
      }
    }
  end

  def fields_mapping(fields)
    fields.each_with_object({}) { |field, hash| hash[field.es_code] = field.index_mapping }
  end
end
