class Clusterer
  CellSize = 115.0

  def initialize(zoom)
    @zoom = zoom
    @width, @height = self.class.cell_size_for zoom
    @clusters = Hash.new { |h, k| h[k] = {lat_sum: 0, lng_sum: 0, count: 0} }
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
    x, y = cell_for site
    cluster = @clusters["#{x}:#{y}"]
    cluster[:id] = "#{@zoom}:#{x}:#{y}"
    cluster[:site_id] = site[:id]
    cluster[:count] += 1
    cluster[:lat_sum] += site[:lat].to_f
    cluster[:lng_sum] += site[:lng].to_f
    cluster
  end

  def clusters
    clusters_to_return = []
    sites_to_return = []

    @clusters.each_value do |cluster|
      count = cluster[:count]
      if count == 1
        sites_to_return.push id: cluster[:site_id], lat: cluster[:lat_sum], lng: cluster[:lng_sum]
      else
        hash = {
          id: cluster[:id],
          lat: cluster[:lat_sum] / count,
          lng: cluster[:lng_sum] / count,
          count: count
        }
        hash[:site_ids] = cluster[:site_ids] if cluster[:site_ids]
        clusters_to_return.push hash
      end
    end

    result = {}
    result[:clusters] = clusters_to_return if clusters_to_return.present?
    result[:sites] = sites_to_return if sites_to_return.present?
    result
  end

  protected

  def cell_for(site)
    x = ((90 + site[:lng]) / @width).floor
    y = ((180 + site[:lat]) / @height).floor
    [x, y]
  end
end
