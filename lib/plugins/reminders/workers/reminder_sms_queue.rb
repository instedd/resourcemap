class ReminderSmsQueue
  @queue = :reminder_sms_queue

  def self.perform(email, reminder_message)
    # send SMS
    #SmsNuntium.notify_sms users, message_notification 
  end
end
