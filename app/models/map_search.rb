class MapSearch
  include SearchBase

  def initialize(collection_ids, options = {})
    @collection_ids = Array(collection_ids)
    @index_names = Collection.index_names_with_options(*@collection_ids, options)
    @bounds = {s: -90, n: 90, w: -180, e: 180}
    @hierarchy = {}
  end

  def zoom=(zoom)
    @zoom = zoom
  end

  def bounds=(bounds)
    @bounds = bounds
    adjust_bounds_to_world_limits
  end

  def exclude_id(id)
    @exclude_id = id
  end

  def selected_hierarchy(hierarchy_code, selected_hierarchy)
    @hierarchy[:code] = hierarchy_code
    @hierarchy[:selected] = selected_hierarchy
  end

  def results
    return {} if @collection_ids.empty?

    listener = clusterer = Clusterer.new(@zoom)
    clusterer.highlight @hierarchy if @hierarchy
    listener = ElasticSearch::SitesAdapter::SkipIdListener.new(listener, @exclude_id) if @exclude_id

    set_bounds_filter

    adapter = ElasticSearch::SitesAdapter.new listener
    adapter.return_property @hierarchy[:code] if @hierarchy[:code]

    adapter.parse stream

    clusterer.clusters
  end

  private

  def set_bounds_filter
    if @zoom
      width, height = Clusterer.cell_size_for @zoom
      extend_to_cell_limits width, height
      adjust_bounds_to_world_limits
    end

    add_filter exists: {field: :location}
    add_filter geo_bounding_box: {
      location: {
        top_left: {
          lat: @bounds[:n],
          lon: @bounds[:w]
        },
        bottom_right: {
          lat: @bounds[:s],
          lon: @bounds[:e]
        },
      }
    }
  end

  def extend_to_cell_limits(width, height)
    extend_to_limit :n,  1, height
    extend_to_limit :s, -1, height
    extend_to_limit :e,  1, width
    extend_to_limit :w, -1, width
  end

  def extend_to_limit(key, sign, size)
    value = @bounds[key].to_f / size
    @bounds[key] = (sign >= 0 ? value.ceil : value.floor) * size
  end

  def adjust_bounds_to_world_limits
    #See https://github.com/elasticsearch/elasticsearch/pull/1602#issuecomment-5978326
    @bounds[:n] = 89.99 if @bounds[:n].to_f > 90
    @bounds[:s] = -89.99 if @bounds[:s].to_f < -90
    @bounds[:e] = 179.99 if @bounds[:e].to_f > 180
    @bounds[:w] = -179.99 if @bounds[:w].to_f < -180
  end

  def collection
    @collection ||= Collection.find @collection_ids[0]
  end

  def stream
    client = Elasticsearch::Client.new
    info = client.transport.hosts.first
    protocol, host, port = info[:protocol], info[:host], info[:port]

    url = "#{protocol}://#{host}:#{port}/#{@index_names}/site/_search"
    body = get_body
    body[:size] = 100_000

    if Rails.logger.level <= Logger::DEBUG
      Rails.logger.debug to_curl(client, body)
    end

    uri = URI(url)
    reader, writer = IO.pipe
    producer = Thread.new(writer) do |io|
      begin
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          request = Net::HTTP::Get.new uri.request_uri
          http.request request, body.to_json do |response|
            response.read_body { |segment| io.write segment.dup.force_encoding("UTF-8") }
          end
        end
      rescue Exception => ex
        Rails.logger.error ex.message + "\n" + ex.backtrace.join("\n")
      ensure
        io.close
      end
    end
    reader
  end
end
