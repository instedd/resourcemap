require 'spec_helper'

describe SiteReminder, :type => :model do
  describe 'telemetry' do
    let!(:collection) { Collection.make }
    let!(:site) { Site.make collection: collection }

    it 'should touch collection lifespan on create' do
      site_reminder = SiteReminder.make_unsaved site: site

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      site_reminder.save
    end

    it 'should touch collection lifespan on update' do
      site_reminder = SiteReminder.make site: site
      site_reminder.touch

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      site_reminder.save
    end

    it 'should touch collection lifespan on destroy' do
      site_reminder = SiteReminder.make site: site

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      site_reminder.destroy
    end
  end
end
