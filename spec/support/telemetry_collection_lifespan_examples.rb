RSpec.shared_examples 'collection lifespan' do |klass, params|
  let!(:collection) { Collection.make }

  it 'should touch collection lifespan on create' do
    record = klass.make_unsaved collection_lifespan_params(params)

    expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection).at_least(:once)

    record.save!
  end

  it 'should touch collection lifespan on update' do
    record = klass.make collection_lifespan_params(params)
    record.touch

    expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection).at_least(:once)

    record.save!
  end

  it 'should touch collection lifespan on destroy' do
    record = klass.make collection_lifespan_params(params)

    expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection).at_least(:once)

    record.destroy
  end

  def collection_lifespan_params(params)
    {collection: collection}.merge(params || {})
  end
end
