class EmailQueue
  @queue = :email_queue

  def self.perform(threshold_id, message_notification)
    threshold = Threshold.find(threshold_id)
    if threshold.is_notify
      ThresholdMailer.notify_email(message_notification, threshold.email_notification).deliver
    end
  end
end
