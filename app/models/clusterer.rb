class Clusterer
  def initialize(zoom)
    @zoom = zoom
    @width, @height = self.class.cell_size_for zoom
    @clusters = Hash.new { |h, k| h[k] = {:sites => [], :lat_sum => 0, :lng_sum => 0} }
  end

  def self.cell_size_for(zoom)
    zoom = zoom.to_i
    zoom = 1 if zoom == 0
    zoom = 2 ** zoom
    [360.0 / zoom, 180.0 / zoom]
  end

  def add(site)
    @x = ((90 + site[:lng]) / @width).floor
    @y = ((180 + site[:lat]) / @height).floor
    cluster = @clusters["#{@x}:#{@y}"]
    cluster[:id] = "#{@zoom}:#{@x}:#{@y}"
    cluster[:sites] << site
    cluster[:lat_sum] += site[:lat]
    cluster[:lng_sum] += site[:lng]
  end

  def clusters
    clusters_to_return = []
    sites_to_return = []

    @clusters.each_value do |cluster|
      sites_length = cluster[:sites].length
      if sites_length == 1
        sites_to_return << cluster[:sites][0]
      else
        clusters_to_return.push({
          :id => cluster[:id],
          :lat => cluster[:lat_sum] / sites_length,
          :lng => cluster[:lng_sum] / sites_length,
          :count => sites_length
        })
      end
    end

    {:clusters => clusters_to_return, :sites => sites_to_return}
  end

  private

  def is_close?(p1, p2)
    (p1[:lat] - p2[:lat]).abs <= @width_distance && (p1[:lng] - p2[:lng]).abs <= @height_distance
  end
end
