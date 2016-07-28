module Telemetry::AccountsCollector

  def self.collect_stats(period)
    {
      "counters" => [{
        "metric" => "accounts",
        "key"    => { },
        "value"  => User.where("created_at < ?", period.end).count,
      }]
    }
  end

end
