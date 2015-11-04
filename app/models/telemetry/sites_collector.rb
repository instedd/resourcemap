module Telemetry::SitesCollector

  def self.collect_stats(period)
    period_end = ActiveRecord::Base.sanitize(period.end)

    results = ActiveRecord::Base.connection.execute <<-SQL
      SELECT collections.id, COUNT(sites.collection_id)
      FROM collections
      LEFT JOIN sites ON sites.collection_id = collections.id
      AND sites.created_at < #{period_end}
      WHERE collections.created_at < #{period_end}
      GROUP BY collections.id
    SQL

    {
      "counters" => results.map { |collection_id, count|
        {
          "metric"  => "sites",
          "key"   => { "collection_id" => collection_id },
          "value" => count
        }
      }
    }
  end


end
