class Clusterer
  CellSize = 115.0

  def initialize(zoom)
    @zoom = zoom
    @width, @height = self.class.cell_size_for zoom
    @clusters = Hash.new { |h, k| h[k] = {:lat_sum => 0, :lng_sum => 0, :count => 0} }
  end

  def self.cell_size_for(zoom)
    zoom = zoom.to_i
    zoom = 1 if zoom == 0
    zoom = 2 ** (zoom + 1)
    [CellSize / zoom, CellSize / zoom]
  end

  def self.zoom_for(size)
    Math.log2(CellSize / size).floor
  end

  def groups=(groups)
    @groups = Hash[groups.map{|x| [x[:id], x]}]
    @group_ids = groups.map{|x| x[:id]}
  end

  def add(site)
    if @group_ids && site[:parent_ids] && (group_id = (site[:parent_ids] & @group_ids)).present?
      group_id = group_id[0]
      group = @groups[group_id]
      cluster = @clusters["g#{group_id}"]
      cluster[:id] ="g#{group_id}"
      cluster[:site_id] = site[:id]
      cluster[:count] += 1
      cluster[:lat_sum] += group[:lat].to_f
      cluster[:lng_sum] += group[:lng].to_f
      cluster[:max_zoom] = group[:max_zoom]
    else
      @x = ((90 + site[:lng]) / @width).floor
      @y = ((180 + site[:lat]) / @height).floor
      cluster = @clusters["#{@x}:#{@y}"]
      cluster[:id] = "#{@zoom}:#{@x}:#{@y}"
      cluster[:site_id] = site[:id]
      cluster[:count] += 1
      cluster[:lat_sum] += site[:lat].to_f
      cluster[:lng_sum] += site[:lng].to_f
    end
  end

  def clusters
    clusters_to_return = []
    sites_to_return = []

    @clusters.each_value do |cluster|
      count = cluster[:count]
      if count == 1
        sites_to_return << {:id => cluster[:site_id], :lat => cluster[:lat_sum], :lng => cluster[:lng_sum]}
      else
        hash = {
          :id => cluster[:id],
          :lat => cluster[:lat_sum] / count,
          :lng => cluster[:lng_sum] / count,
          :count => count
        }
        hash[:max_zoom] = cluster[:max_zoom] if cluster[:max_zoom]
        clusters_to_return.push hash
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
