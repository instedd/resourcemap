class ReminderTask
  def self.perform    
    r = Reminder.first
    r.reminder_message = r.reminder_message + "1"
    r.save
  end
end
