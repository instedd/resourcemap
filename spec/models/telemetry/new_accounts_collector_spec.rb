require 'spec_helper'

describe Telemetry::NewAccountsCollector do

  it "counts accounts created in current period" do
    Timecop.freeze(Time.now)
    p0 = currente_period
    
    3.times { User.make }

    expect(stats(p0)).to eq({
      "counters" => [
        { "metric"  => "new_accounts", "key" => {}, "value" => 3 }
      ]
    })

    advance_period
    p1 = currente_period

    7.times { User.make }

    expect(stats(p1)).to eq({
      "counters" => [
        { "metric"  => "new_accounts", "key" => {}, "value" => 7 }
      ]
    })
    
    advance_period
    10.times { User.make }
    
    # do not count accounts created in later periods
    expect(stats(p1)).to eq({
      "counters" => [
        { "metric"  => "new_accounts", "key" => {}, "value" => 7 }
      ]
    })
  end

  def stats(period)
    Telemetry::NewAccountsCollector.collect_stats(period)
  end

  def currente_period
    InsteddTelemetry::Period.current    
  end

  def current_period_stats
    stats(currente_period)
  end

  def advance_period
    Timecop.freeze(Time.now + InsteddTelemetry::Period.span)    
  end

end
