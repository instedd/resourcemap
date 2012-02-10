class Clusterer
  def initialize(zoom)
    @zoom = zoom
    @width, @height = self.class.cell_size_for zoom
    @clusters = Hash.new { |h, k| h[k] = {:lat_sum => 0, :lng_sum => 0, :count => 0} }
  end

  def self.cell_size_for(zoom)
    zoom = zoom.to_i
    zoom = 1 if zoom == 0
    zoom = 2 ** (zoom + 1)
    [180.0 / zoom, 180.0 / zoom]
  end

  def add(id, lat, lng)
    @x = ((90 + lng) / @width).floor
    @y = ((180 + lat) / @height).floor
    cluster = @clusters["#{@x}:#{@y}"]
    cluster[:id] = "#{@zoom}:#{@x}:#{@y}"
    cluster[:site_id] = id
    cluster[:count] += 1
    cluster[:lat_sum] += lat
    cluster[:lng_sum] += lng
  end

  def clusters
    clusters_to_return = []
    sites_to_return = []

    @clusters.each_value do |cluster|
      count = cluster[:count]
      if count == 1
        sites_to_return << {:id => cluster[:site_id], :lat => cluster[:lat_sum], :lng => cluster[:lng_sum]}
      else
        clusters_to_return.push({
          :id => cluster[:id],
          :lat => cluster[:lat_sum] / count,
          :lng => cluster[:lng_sum] / count,
          :count => count
        })
      end
    end

    result = {}
    result[:clusters] = clusters_to_return if clusters_to_return.present?
    result[:sites] = sites_to_return if sites_to_return.present?
    result
  end

  private

  def is_close?(p1, p2)
    (p1[:lat] - p2[:lat]).abs <= @width_distance && (p1[:lng] - p2[:lng]).abs <= @height_distance
  end
end
