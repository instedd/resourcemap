require 'spec_helper'

describe Telemetry::ActivitiesCollector do

  it "counts activities grouped by collection" do
    period = InsteddTelemetry::Period.current
    
    c1 = Collection.make
    10.times { Activity.make collection: c1, item_type: 'site' }
    
    c2 = Collection.make
    17.times { Activity.make collection: c2, item_type: 'site' }

    expect(stats(period)).to eq({
      "counters" => [
        {
          "metric"  => "activities",
          "key"   => { "collection_id" => c1.id },
          "value" => 10
        },
        {
          "metric"  => "activities",
          "key"   => { "collection_id" => c2.id },
          "value" => 17
        }
      ]
    })
  end

  it "takes into account current period" do
    Timecop.freeze(Time.now)
    c = Collection.make
    10.times { Activity.make collection: c, item_type: 'site' }
    p0 = InsteddTelemetry::Period.current

    Timecop.freeze(Time.now + InsteddTelemetry::Period.span)
    2.times { Activity.make collection: c, item_type: 'site' }
    p1 = InsteddTelemetry::Period.current

    expect(stats(p0)).to eq({
      "counters" => [
        {
          "metric"  => "activities",
          "key"   => { "collection_id" => c.id },
          "value" => 10
        }
      ]
    })

    expect(stats(p1)).to eq({
      "counters" => [
        {
          "metric"  => "activities",
          "key"   => { "collection_id" => c.id },
          "value" => 12
        }
      ]
    })
  end

  def stats(period)
    Telemetry::ActivitiesCollector.collect_stats(period)
  end

end
