module Telemetry::FieldsCollector

  def self.collect_stats(period)
    period_end = ActiveRecord::Base.sanitize(period.end)

    results = ActiveRecord::Base.connection.execute <<-SQL
      SELECT collections.id, COUNT(fields.collection_id)
      FROM collections
      LEFT JOIN fields ON fields.collection_id = collections.id
      AND fields.created_at < #{period_end}
      WHERE collections.created_at < #{period_end}
      GROUP BY collections.id
    SQL

    counters = results.map do |collection_id, count|
      {
        metric: 'fields_by_collection',
        key: {collection_id: collection_id},
        value: count
      }
    end

    {counters: counters}
  end

end
