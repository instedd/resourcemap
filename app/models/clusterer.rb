class Clusterer
  CellSize = 115.0

  def initialize(zoom)
    @zoom = zoom
    @width, @height = self.class.cell_size_for zoom
    @clusters = Hash.new { |h, k| h[k] = {lat_sum: 0, lng_sum: 0, count: 0, parent_ids: []} }
  end

  def self.cell_size_for(zoom)
    zoom = zoom.to_i
    zoom = 2 ** (zoom)
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
      add_group site, @groups[group_id[0]]
    else
      add_non_group site
    end
  end

  def clusters
    first_pass = first_pass_clusters
    if first_pass[:clusters]
      clusterer = Clusterer.new(@zoom)
      first_pass[:clusters].each do |cluster|
        new_cluster = clusterer.add_non_group cluster, cluster[:count]
        new_cluster[:max_zoom] = cluster[:max_zoom]
        new_cluster[:group_ids] ||= []
        new_cluster[:group_ids] << cluster[:id]
      end
      if first_pass[:sites]
        first_pass[:sites].each do |site|
          new_cluster = clusterer.add_non_group site
          new_cluster[:group_ids] ||= []
          new_cluster[:group_ids] << site[:id]
          new_cluster[:site_ids] ||= []
          new_cluster[:site_ids] << site[:id]
        end
      end
      grouped_clusters = clusterer.first_pass_clusters
      if grouped_clusters[:clusters]
        grouped_clusters[:clusters].each do |cluster|
          if cluster[:group_ids].length == 1
            cluster[:id] = cluster[:group_ids][0]
          else
            cluster.delete :max_zoom
            first_pass[:sites].delete_if {|s| cluster[:site_ids].include?(s[:id])} if cluster[:site_ids]
          end
          cluster.delete :group_ids
          cluster.delete :site_ids
        end
        first_pass[:clusters] = grouped_clusters[:clusters]
      end
    end
    first_pass.delete(:sites) if first_pass[:sites].blank?
    first_pass
  end

  protected

  def add_group(site, group)
    cluster = @clusters["g#{group[:id]}"]
    cluster[:id] ="g#{group[:id]}"
    cluster[:site_id] = site[:id]
    cluster[:count] += 1
    cluster[:lat_sum] += group[:lat].to_f
    cluster[:lng_sum] += group[:lng].to_f
    cluster[:max_zoom] = group[:max_zoom]
    cluster[:parent_ids] |= site[:parent_ids] if site[:parent_ids]
    cluster
  end

  def add_non_group(site, weight = 1)
    x, y = cell_for site
    cluster = @clusters["#{x}:#{y}"]
    cluster[:id] = "#{@zoom}:#{x}:#{y}"
    cluster[:site_id] = site[:id]
    cluster[:count] += weight
    cluster[:lat_sum] += weight * site[:lat].to_f
    cluster[:lng_sum] += weight * site[:lng].to_f
    cluster[:parent_ids] |= site[:parent_ids] if site[:parent_ids]
    cluster
  end

  def cell_for(site)
    x = ((90 + site[:lng]) / @width).floor
    y = ((180 + site[:lat]) / @height).floor
    [x, y]
  end

  def first_pass_clusters
    clusters_to_return = []
    sites_to_return = []

    @clusters.each_value do |cluster|
      count = cluster[:count]
      if count == 1
        site = {id: cluster[:site_id], lat: cluster[:lat_sum], lng: cluster[:lng_sum]}
        site[:parent_ids] = cluster[:parent_ids] if cluster[:parent_ids].present?
        sites_to_return << site
      else
        hash = {
          id: cluster[:id],
          lat: cluster[:lat_sum] / count,
          lng: cluster[:lng_sum] / count,
          count: count
        }
        hash[:max_zoom] = cluster[:max_zoom] if cluster[:max_zoom]
        hash[:group_ids] = cluster[:group_ids] if cluster[:group_ids]
        hash[:site_ids] = cluster[:site_ids] if cluster[:site_ids]
        hash[:parent_ids] = cluster[:parent_ids] if cluster[:parent_ids].present?
        clusters_to_return.push hash
      end
    end

    result = {}
    result[:clusters] = clusters_to_return if clusters_to_return.present?
    result[:sites] = sites_to_return if sites_to_return.present?
    result
  end

  def internal_clusters
    @clusters
  end

  def is_close?(p1, p2)
    (p1[:lat] - p2[:lat]).abs <= @width_distance && (p1[:lng] - p2[:lng]).abs <= @height_distance
  end
end
