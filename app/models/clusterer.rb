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

  def exclude_id(id)
    @exclude_id = id
  end

  def add(id, lat, lng, parent_ids = [])
    return if id == @exclude_id

    if @group_ids && (group_id = (parent_ids & @group_ids)).present?
      group_id = group_id[0]
      group = @groups[group_id]
      cluster = @clusters["g#{group_id}"]
      cluster[:id] ="g#{group_id}"
      cluster[:site_id] = id
      cluster[:count] += 1
      cluster[:lat_sum] += group[:lat].to_f
      cluster[:lng_sum] += group[:lng].to_f
    else
      @x = ((90 + lng) / @width).floor
      @y = ((180 + lat) / @height).floor
      cluster = @clusters["#{@x}:#{@y}"]
      cluster[:id] = "#{@zoom}:#{@x}:#{@y}"
      cluster[:site_id] = id
      cluster[:count] += 1
      cluster[:lat_sum] += lat.to_f
      cluster[:lng_sum] += lng.to_f
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
