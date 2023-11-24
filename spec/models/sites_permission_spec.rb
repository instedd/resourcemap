require 'spec_helper'

describe SitesPermission, :type => :model do
  it { is_expected.to belong_to :membership }

  describe "convert to json" do
    describe '#to_json' do
      subject { super().to_json }
      it { is_expected.not_to include "\"id\":" }
    end

    describe '#to_json' do
      subject { super().to_json }
      it { is_expected.not_to include "\"membership_id\":" }
    end

    describe '#to_json' do
      subject { super().to_json }
      it { is_expected.not_to include "\"created_at\":" }
    end

    describe '#to_json' do
      subject { super().to_json }
      it { is_expected.not_to include "\"updated_at\":" }
    end
  end

  describe 'telemetry' do
    let!(:user) { User.make! }
    let!(:collection) { Collection.make! }
    let!(:membership) { Membership.make! collection: collection, user: user }

    it 'should touch collection lifespan on create' do
      sites_permission = SitesPermission.make membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      sites_permission.save
    end

    it 'should touch collection lifespan on update' do
      sites_permission = SitesPermission.make! membership: membership
      sites_permission.touch

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      sites_permission.save
    end

    it 'should touch collection lifespan on destroy' do
      sites_permission = SitesPermission.make! membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      sites_permission.destroy
    end

    it 'should touch user lifespan on create' do
      sites_permission = SitesPermission.make membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      sites_permission.save
    end

    it 'should touch user lifespan on update' do
      sites_permission = SitesPermission.make! membership: membership
      sites_permission.touch

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      sites_permission.save
    end

    it 'should touch user lifespan on destroy' do
      sites_permission = SitesPermission.make! membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      sites_permission.destroy
    end
  end
end
