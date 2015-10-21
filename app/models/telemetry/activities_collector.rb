module Telemetry::ActivitiesCollector

  def self.collect_stats(period)
    query = Activity.select(["collection_id", "count(*)"])
                .group("collection_id")
                .where("created_at < ?", period.end)
                .to_sql

    results = ActiveRecord::Base.connection.execute(query)

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