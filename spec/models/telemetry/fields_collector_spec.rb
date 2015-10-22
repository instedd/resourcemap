require 'spec_helper'

describe Telemetry::FieldsCollector do

  let(:period) { InsteddTelemetry::Period.current }

  it 'counts fields by collection' do
    collection_1 = Collection.make
    collection_2 = Collection.make
    collection_3 = Collection.make

    Field::NumericField.make collection: collection_1, created_at: period.end - 1.day
    Field::SelectManyField.make collection: collection_1, created_at: period.end - 7.days
    Field::UserField.make collection: collection_1, created_at: period.end - 60.days
    Field::YesNoField.make collection: collection_1, created_at: period.end + 1.day

    Field::UserField.make collection: collection_2, created_at: period.end - 10.days
    Field::NumericField.make collection: collection_2, created_at: period.end - 27.days

    Field::SelectManyField.make collection: collection_3, created_at: period.end + 5.days

    stats = Telemetry::FieldsCollector.collect_stats period
    counters = stats[:counters]

    expect(counters.size).to eq(2)

    expect(counters).to include({
      metric: 'fields_by_collection',
      key: {collection_id: collection_1.id},
      value: 3
    })

    expect(counters).to include({
      metric: 'fields_by_collection',
      key: {collection_id: collection_2.id},
      value: 2
    })
  end

end
