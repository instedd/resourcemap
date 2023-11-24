require 'spec_helper'

describe Telemetry::Lifespan do

  before :each do
    @now = Time.now
    Timecop.freeze(@now)
  end

  after :each do
    Timecop.return
  end

  it 'updates the collection lifespan' do
    collection = Collection.make! created_at: @now - 1.week

    expect(InsteddTelemetry).to receive(:timespan_update).with('collection_lifespan', {collection_id: collection.id}, collection.created_at, @now)

    Telemetry::Lifespan.touch_collection collection
  end

  it 'updates the collection users lifespan' do
    user1 = User.make!
    user2 = User.make!
    collection = Collection.make!
    Membership.make! user: user1, collection: collection
    Membership.make! user: user2, collection: collection

    expect(Telemetry::Lifespan).to receive(:touch_user).with(user1).at_least(:once)
    expect(Telemetry::Lifespan).to receive(:touch_user).with(user2).at_least(:once)

    Telemetry::Lifespan.touch_collection collection.reload
  end

  it 'updates the account lifespan' do
    user = User.make! created_at: @now - 1.week

    expect(InsteddTelemetry).to receive(:timespan_update).with('account_lifespan', {account_id: user.id}, user.created_at, @now)

    Telemetry::Lifespan.touch_user user
  end

end
