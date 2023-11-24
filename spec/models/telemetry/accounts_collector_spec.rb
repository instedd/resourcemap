require 'spec_helper'

describe Telemetry::AccountsCollector do

  it "counts accounts for current period" do
    3.times { User.make! }
    period = InsteddTelemetry::Period.current

    stats = Telemetry::AccountsCollector.collect_stats(period)

    expect(stats).to eq({
      "counters" => [
        {
        "metric" => "accounts",
        "key" => {},
        "value" => 3
        }
      ]
    })
  end

  it "takes into account period date" do
    Timecop.freeze(Time.now)
    3.times { User.make! }
    p0 = InsteddTelemetry::Period.current

    Timecop.freeze(Time.now + InsteddTelemetry::Period.span)
    2.times { User.make! }
    p1 = InsteddTelemetry::Period.current

    expect(Telemetry::AccountsCollector.collect_stats(p0)).to eq({
      "counters" => [{
        "metric" => "accounts",
        "key" => {},
        "value" => 3
      }]
    })

    expect(Telemetry::AccountsCollector.collect_stats(p1)).to eq({
      "counters" => [{
        "metric" => "accounts",
        "key" => {},
        "value" => 5
      }]
    })
  end

end
