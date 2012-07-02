class EmailQueue
  @queue = :email_queue
  def self.perform(threshold)
    if threshold["is_notify"]
      ThresholdMailer.notify_email(threshold["message_notification"], threshold["email_notification"]).deliver
    end
  end
end
