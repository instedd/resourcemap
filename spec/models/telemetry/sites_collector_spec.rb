require 'spec_helper'

describe Telemetry::SitesCollector do

  it "counts sites grouped by collection_id" do
    c1 = Collection.make
    3.times { c1.sites.make }

    c2 = Collection.make
    5.times { c2.sites.make }

    period = InsteddTelemetry::Period.current

    expect(stats(period)).to eq({
      "counters" => [
        {
          "metric"  => "sites",
          "key"   => { "collection_id" => c1.id },
          "value" => 3
        },
        {
          "metric"  => "sites",
          "key"   => { "collection_id" => c2.id },
          "value" => 5
        }
      ]
    })
  end

  it "takes into account current period" do
    Timecop.freeze(Time.now)
    c = Collection.make
    3.times { c.sites.make }
    p0 = InsteddTelemetry::Period.current

    Timecop.freeze(Time.now + InsteddTelemetry::Period.span)
    10.times {c.sites.make }
    p1 = InsteddTelemetry::Period.current

    expect(stats(p0)).to eq({
      "counters" => [
        {
          "metric"  => "sites",
          "key"   => { "collection_id" => c.id },
          "value" => 3
        }
      ]
    })

    expect(stats(p1)).to eq({
      "counters" => [
        {
          "metric"  => "sites",
          "key"   => { "collection_id" => c.id },
          "value" => 13
        }
      ]
    })

  end

  def stats(period)
    Telemetry::SitesCollector.collect_stats(period)
  end

end
