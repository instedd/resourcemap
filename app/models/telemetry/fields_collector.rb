module Telemetry::FieldsCollector

  def self.collect_stats(period)
    fields_by_collection = Field.where('created_at < ?', period.end).group(:collection_id).count

    counters = fields_by_collection.map do |collection_id, count|
      {
        metric: 'fields_by_collection',
        key: {collection_id: collection_id},
        value: count
      }
    end

    {counters: counters}
  end

end
