require 'spec_helper'

describe Reminder, :type => :model do
  include_examples 'collection lifespan', described_class

  let(:collection) { Collection.make }
  let(:repeat) { Repeat.make }

  it "should reset all reminders recurrence rule" do
    Reminder.connection.execute "INSERT INTO `reminders` (`id`, `repeat_id`, `collection_id`, `name`, `schedule`, `reminder_message`, `status`, `created_at`, `updated_at`) VALUES (17, #{repeat.id}, #{collection.id}, 'Gas station reminder', '---\n:start_time: 2012-01-03 08:20:00\n:rrules: []\n:rtimes: []\n:extimes: []\n', 'This is reminder on Gas station reminder', 1, '#{Time.now.utc.to_s(:db)}', '#{Time.now.utc.to_s(:db)}');"
    Reminder.reset_reminders_recurrence_rule
    expect(Reminder.first.schedule.recurrence_rules.count).to eq(1)
  end

  # After saving sites with properties as a hash, load is failing with "TypeError: can't convert Hash into String"
  it "should serialize site's properties to json" do
    col = Collection.make
    layer = col.layers.make
    field = layer.text_fields.make code: 'text'
    site = Site.make(collection_id: col.id, properties: {field.id.to_s => 'text'})
    reminder = Reminder.make collection_id: col.id, sites: [site]
    loaded = Reminder.first
    expect(loaded).to eq(reminder)
    expect(loaded.sites.first.properties).to eq({field.id.to_s => 'text'})
  end
end
