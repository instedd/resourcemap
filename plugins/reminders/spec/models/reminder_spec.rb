require 'spec_helper'

describe Reminder, :type => :model do
  let(:collection) { Collection.make }
  let(:repeat) { Repeat.make }

  it "should reset all reminders recurrence rule" do
    Reminder.connection.execute "INSERT INTO `reminders` (`id`, `repeat_id`, `collection_id`, `name`, `schedule`, `reminder_message`, `status`, `created_at`, `updated_at`) VALUES (17, #{repeat.id}, #{collection.id}, 'Gas station reminder', '---\n:start_time: 2012-01-03 08:20:00\n:rrules: []\n:exrules: []\n:rtimes: []\n:extimes: []\n', 'This is reminder on Gas station reminder', 1, '#{Time.now.utc.to_s(:db)}', '#{Time.now.utc.to_s(:db)}');"
    Reminder.reset_reminders_recurrence_rule
    expect(Reminder.first.schedule.recurrence_rules.count).to eq(1)
  end
end
