module Telemetry::ActivitiesCollector

  def self.collect_stats(period)
    period_end = ActiveRecord::Base.sanitize(period.end)

    results = ActiveRecord::Base.connection.execute <<-SQL
      SELECT collections.id, COUNT(activities.collection_id)
      FROM collections
      LEFT JOIN activities ON activities.collection_id = collections.id
      AND activities.created_at < #{period_end}
      WHERE collections.created_at < #{period_end}
      GROUP BY collections.id
    SQL

    {
      "counters" => results.map { |collection_id, count|
        {
          "metric"  => "activities",
          "key"   => { "collection_id" => collection_id },
          "value" => count
        }
      }
    }
  end


end
