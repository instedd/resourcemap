require 'spec_helper'

describe NamePermission, :type => :model do
  describe 'telemetry' do
    let!(:user) { User.make }
    let!(:collection) { Collection.make }
    let!(:membership) { Membership.make collection: collection, user: user }

    it 'should touch collection lifespan on create' do
      name_permission = NamePermission.make_unsaved membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      name_permission.save
    end

    it 'should touch collection lifespan on update' do
      name_permission = NamePermission.make membership: membership
      name_permission.touch

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      name_permission.save
    end

    it 'should touch collection lifespan on destroy' do
      name_permission = NamePermission.make membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      name_permission.destroy
    end

    it 'should touch user lifespan on create' do
      name_permission = NamePermission.make_unsaved membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      name_permission.save
    end

    it 'should touch user lifespan on update' do
      name_permission = NamePermission.make membership: membership
      name_permission.touch

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      name_permission.save
    end

    it 'should touch user lifespan on destroy' do
      name_permission = NamePermission.make membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      name_permission.destroy
    end
  end
end
