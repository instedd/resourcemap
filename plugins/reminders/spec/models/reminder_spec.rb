require 'spec_helper'

describe Reminder do
  let!(:collection) { Collection.make }
  let!(:repeat) { Repeat.make }

  it "should reset all reminders recurrence rule" do
    Reminder.connection.execute "INSERT INTO `reminders` (`id`, `repeat_id`, `collection_id`, `name`, `schedule`, `reminder_message`, `status`) VALUES (17, #{repeat.id}, #{collection.id}, 'Gas station reminder', '---\n:start_date: 2012-01-03 08:20:00\n:rrules: []\n:exrules: []\n:rtimes: []\n:extimes: []\n', 'This is reminder on Gas station reminder', 1);"
    Reminder.reset_reminders_recurrence_rule
    Reminder.first.schedule.recurrence_rules.count.should == 1
  end
end
