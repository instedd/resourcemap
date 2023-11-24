require 'spec_helper'

describe LocationPermission, :type => :model do
  describe 'telemetry' do
    let!(:user) { User.make! }
    let!(:collection) { Collection.make! }
    let!(:membership) { Membership.make! collection: collection, user: user }

    it 'should touch collection lifespan on create' do
      location_permission = LocationPermission.make membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      location_permission.save
    end

    it 'should touch collection lifespan on update' do
      location_permission = LocationPermission.make! membership: membership
      location_permission.touch

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      location_permission.save
    end

    it 'should touch collection lifespan on destroy' do
      location_permission = LocationPermission.make! membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      location_permission.destroy
    end

    it 'should touch user lifespan on create' do
      location_permission = LocationPermission.make membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      location_permission.save
    end

    it 'should touch user lifespan on update' do
      location_permission = LocationPermission.make! membership: membership
      location_permission.touch

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      location_permission.save
    end

    it 'should touch user lifespan on destroy' do
      location_permission = LocationPermission.make! membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      location_permission.destroy
    end
  end
end
