module Telemetry::AlertConditionsCollector

  def self.collect_stats(period)
    counts = Hash.new(0)

    Threshold.where('created_at < ?', period.end).find_each do |t|
      counts[t.collection_id] += t.conditions.size
    end

    {
      "counters" => counts.map { |collection_id, count|
        {
          "metric"  => "alert_conditions",
          "key"   => { "collection_id" => collection_id },
          "value" => count
        }
      }
    }
  end


end