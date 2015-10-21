module Telemetry::SitesCollector

  def self.collect_stats(period)
    query = Site.select(["collection_id", "count(*)"])
                .where("created_at < ?", period.end)
                .group("collection_id")
                .to_sql

    results = ActiveRecord::Base.connection.execute(query)

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