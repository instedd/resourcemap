require 'spec_helper'

describe Telemetry::FieldsCollector do

  let(:period) { InsteddTelemetry::Period.current }

  it 'counts fields by collection' do
    collection_1 = Collection.make created_at: period.end - 1.day
    collection_2 = Collection.make created_at: period.end - 7.days
    collection_3 = Collection.make created_at: period.end + 1.days

    layer_1 = Layer.make collection: collection_1
    layer_2 = Layer.make collection: collection_2
    layer_3 = Layer.make collection: collection_3

    Field::NumericField.make collection: collection_1, layer: layer_1, created_at: period.end - 1.day
    Field::SelectManyField.make collection: collection_1, layer: layer_1, created_at: period.end - 7.days
    Field::UserField.make collection: collection_1, layer: layer_1, created_at: period.end - 60.days
    Field::YesNoField.make collection: collection_1, layer: layer_1, created_at: period.end + 1.day

    Field::UserField.make collection: collection_2, layer: layer_2, created_at: period.end - 10.days
    Field::NumericField.make collection: collection_2, layer: layer_2, created_at: period.end - 27.days

    Field::SelectManyField.make collection: collection_3, layer: layer_3, created_at: period.end + 5.days

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

  it 'counts collections with 0 fields'  do
    collection_1 = Collection.make created_at: period.end - 5.days
    collection_2 = Collection.make created_at: period.end - 1.day
    collection_3 = Collection.make created_at: period.end + 1.day

    layer_2 = Layer.make collection: collection_2
    layer_3 = Layer.make collection: collection_3

    Field::NumericField.make collection: collection_2, layer: layer_2, created_at: period.end + 1.day
    Field::NumericField.make collection: collection_3, layer: layer_3, created_at: period.end + 3.days

    stats = Telemetry::FieldsCollector.collect_stats period
    counters = stats[:counters]

    expect(counters.size).to eq(2)
    expect(counters).to include({
      metric: 'fields_by_collection',
      key: { collection_id: collection_1.id },
      value: 0
    })
    expect(counters).to include({
      metric: 'fields_by_collection',
      key: { collection_id: collection_2.id },
      value: 0
    })
  end

end
