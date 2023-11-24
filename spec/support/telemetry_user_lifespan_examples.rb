RSpec.shared_examples 'user lifespan' do |klass, params|
  let!(:user) { User.make! }

  it 'should touch user lifespan on create' do
    record = klass.make user_lifespan_params(params)

    expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

    record.save
  end

  it 'should touch user lifespan on update' do
    record = klass.make! user_lifespan_params(params)
    record.touch

    expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

    record.save
  end

  it 'should touch user lifespan on destroy' do
    record = klass.make! user_lifespan_params(params)

    expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

    record.destroy
  end

  def user_lifespan_params(params)
    {user: user}.merge(params || {})
  end
end
