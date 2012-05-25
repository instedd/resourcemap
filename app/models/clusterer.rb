class Clusterer
  CellSize = 115.0

  def initialize(zoom)
    @zoom = zoom
    @width, @height = self.class.cell_size_for zoom
    @clusters = Hash.new { |h, k| h[k] = {lat_sum: 0, lng_sum: 0, count: 0, min_lat: 90, max_lat: -90, min_lng: 180, max_lng: -180} }
    @sites = []
    @clustering_enabled = @zoom < 20
  end

  def self.cell_size_for(zoom)
    zoom = zoom.to_i
    zoom = 2 ** (zoom)
    [CellSize / zoom, CellSize / zoom]
  end

  def self.zoom_for(size)
    Math.log2(CellSize / size).floor
  end

  def add(site)
    lat, lng = site[:lat].to_f, site[:lng].to_f
    if @clustering_enabled
      x, y = cell_for site
      cluster = @clusters["#{x}:#{y}"]
      cluster[:id] = "#{@zoom}:#{x}:#{y}"
      cluster[:site_id] = site[:id]
      cluster[:name] = site[:name]
      cluster[:count] += 1
      cluster[:min_lat] = lat if lat < cluster[:min_lat]
      cluster[:min_lng] = lng if lng < cluster[:min_lng]
      cluster[:max_lat] = lat if lat > cluster[:max_lat]
      cluster[:max_lng] = lng if lng > cluster[:max_lng]
      cluster[:lat_sum] += lat
      cluster[:lng_sum] += lng
    else
      @sites.push id: site[:id], name:site[:name],lat: lat, lng: lng
    end
  end

  def clusters
    result = {}

    if @clustering_enabled
      clusters_to_return = []
      sites_to_return = []

      @clusters.each_value do |cluster|
        count = cluster[:count]
        if count == 1
          sites_to_return.push id: cluster[:site_id], name: cluster[:name], lat: cluster[:lat_sum], lng: cluster[:lng_sum]
        else
          hash = {
            id: cluster[:id],
            lat: cluster[:lat_sum] / count,
            lng: cluster[:lng_sum] / count,
            min_lat: cluster[:min_lat],
            min_lng: cluster[:min_lng],
            max_lat: cluster[:max_lat],
            max_lng: cluster[:max_lng],
            count: count
          }
          hash[:site_ids] = cluster[:site_ids] if cluster[:site_ids]
          clusters_to_return.push hash
        end
      end

      result[:clusters] = clusters_to_return if clusters_to_return.present?
      result[:sites] = sites_to_return if sites_to_return.present?
    else
      result[:sites] = @sites
    end

    result
  end

  protected

  def cell_for(site)
    x = ((90 + site[:lng]) / @width).floor
    y = ((180 + site[:lat]) / @height).floor
    [x, y]
  end
end
