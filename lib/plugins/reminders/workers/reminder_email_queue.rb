class ReminderEmailQueue
  @queue = :reminder_email_queue

  def self.perform(phone_number, reminder_message)
    # send Email  
  end
