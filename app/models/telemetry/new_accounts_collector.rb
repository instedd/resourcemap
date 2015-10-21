module Telemetry::NewAccountsCollector

  def self.collect_stats(period)
    count = User.where("created_at >= ?", period.beginning)
                .where("created_at < ?", period.end)
                .count
    {
      "counters" => [
        {
          "metric"  => "new_accounts",
          "key"   => {},
          "value" => count
        }
      ]
    }
  end


end