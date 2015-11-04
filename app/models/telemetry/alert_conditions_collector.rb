module Telemetry::AlertConditionsCollector

  def self.collect_stats(period)
    # Count for collections that have thresholds
    counts = Hash.new(0)

    Threshold.where('created_at < ?', period.end).find_each do |t|
      counts[t.collection_id] += t.conditions.size
    end

    # Count for collections that don't have thresholds
    period_end = ActiveRecord::Base.sanitize(period.end)

    empty_results = ActiveRecord::Base.connection.execute <<-SQL
      SELECT collections.id
      FROM collections
      LEFT JOIN thresholds ON thresholds.collection_id = collections.id
      AND thresholds.created_at < #{period_end}
      WHERE collections.created_at < #{period_end}
      AND thresholds.collection_id IS NULL
    SQL

    # Join results
    counters = counts.map do |collection_id, count|
      {
        "metric"  => "alert_conditions",
        "key"   => { "collection_id" => collection_id },
        "value" => count
      }
    end

    empty_counters = empty_results.map do |collection_id, _|
      {
        "metric"  => "alert_conditions",
        "key"   => { "collection_id" => collection_id },
        "value" => 0
      }
    end


    { "counters" => counters.concat(empty_counters) }
  end

end
