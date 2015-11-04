module Telemetry::MembershipsCollector

  def self.collect_stats(period)
    period_end = ActiveRecord::Base.sanitize(period.end)

    results = ActiveRecord::Base.connection.execute <<-SQL
      SELECT collections.id, COUNT(memberships.collection_id)
      FROM collections
      LEFT JOIN memberships ON memberships.collection_id = collections.id
      AND memberships.created_at < #{period_end}
      WHERE collections.created_at < #{period_end}
      GROUP BY collections.id
    SQL

    {
      "counters" => results.map { |collection_id, count|
        {
          "metric"  => "memberships",
          "key"   => { "collection_id" => collection_id },
          "value" => count
        }
      }
    }
  end


end
