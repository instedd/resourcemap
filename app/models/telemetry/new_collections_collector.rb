module Telemetry::NewCollectionsCollector

  def self.collect_stats(period)
    count = Collection.where("created_at >= ?", period.beginning)
                      .where("created_at < ?", period.end)
                      .count
    {
      "counters" => [
        {
          "metric"  => "new_collections",
          "key"   => {},
          "value" => count
        }
      ]
    }
  end


end
