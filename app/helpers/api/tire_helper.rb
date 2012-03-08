module Api::TireHelper
  def parents_as_hash(results)
    parent_ids = results.map{|x| x['_source']['parent_ids']}.flatten.uniq.compact
    Hash[Site.find(parent_ids).map{|x| [x.id, x]}]
  end
end
