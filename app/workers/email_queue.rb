class EmailQueue
  @queue = :email_queue

  def self.perform(users, message_notification)
    ThresholdMailer.notify_email(users, message_notification).deliver
  end
end
