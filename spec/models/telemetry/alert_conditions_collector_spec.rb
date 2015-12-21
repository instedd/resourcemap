require 'spec_helper'

describe Telemetry::AlertConditionsCollector do

  it "counts alert conditions by collection" do
    period = InsteddTelemetry::Period.current

    c1 = Collection.make
    create_fields(c1, 3)
    create_threshold_with_conditions(c1, 3)
    create_threshold_with_conditions(c1, 2)

    c2 = Collection.make
    create_fields(c2, 7)
    create_threshold_with_conditions(c2, 7)

    expect(stats(period)).to eq({
      "counters" => [
        {
          "metric"  => "alert_conditions",
          "key"   => { "collection_id" => c1.id },
          "value" => 5
        },
        {
          "metric"  => "alert_conditions",
          "key"   => { "collection_id" => c2.id },
          "value" => 7
        }
      ]
    })
  end

  it "doesn't count thresholds created after current period" do
    Timecop.freeze(Time.now)

    c1 = Collection.make
    create_fields(c1, 3)
    create_threshold_with_conditions(c1, 3)
    p0 = InsteddTelemetry::Period.current

    Timecop.freeze(Time.now + InsteddTelemetry::Period.span)
    create_threshold_with_conditions(c1, 1)
    p1 = InsteddTelemetry::Period.current

    expect(stats(p0)).to eq({
      "counters" => [
        {
          "metric"  => "alert_conditions",
          "key"   => { "collection_id" => c1.id },
          "value" => 3
        }
      ]
    })

    expect(stats(p1)).to eq({
      "counters" => [
        {
          "metric"  => "alert_conditions",
          "key"   => { "collection_id" => c1.id },
          "value" => 4
        }
      ]
    })
  end

  it 'counts collections without alert conditions' do
    period = InsteddTelemetry::Period.current

    c1 = Collection.make
    c2 = Collection.make
    c3 = Collection.make created_at: period.end + 1.day

    Timecop.freeze(period.end + 1.day) do
      create_fields(c2, 3)
      create_threshold_with_conditions(c2, 3)

      create_fields(c3, 3)
      create_threshold_with_conditions(c3, 3)
    end

    counters = stats(period)['counters']

    expect(counters.size).to eq(2)

    expect(counters).to include({
      "metric"  => "alert_conditions",
      "key"   => { "collection_id" => c1.id },
      "value" => 0
    })

    expect(counters).to include({
      "metric"  => "alert_conditions",
      "key"   => { "collection_id" => c2.id },
      "value" => 0
    })
  end

  def create_fields(collection, count)
    layer = collection.layers.make
    count.times do |i|
      Field::TextField.create!({
        name: "foo_#{i}",
        code: "foo_#{i}",
        ord: i,
        collection: collection,
        layer: layer
      })
    end
    collection.reload
  end

  def create_threshold_with_conditions(collection, count)
    fields = collection.fields.take(count)

    conditions = fields.map do |f|
      { field: f, op: :eq, type: :value, value: "asd" }
    end

    collection.thresholds.make conditions: conditions.to_a
  end

  def stats(period)
    Telemetry::AlertConditionsCollector.collect_stats(period)
  end

end
