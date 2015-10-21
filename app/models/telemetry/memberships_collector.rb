module Telemetry::MembershipsCollector

  def self.collect_stats(period)
    query = Membership.select(["collection_id", "count(*)"])
                .where("created_at < ?", period.end)
                .group("collection_id")
                .to_sql

    results = ActiveRecord::Base.connection.execute(query)

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