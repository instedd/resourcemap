class SmsQueue
  @queue = :sms_queue
  def self.perform users, message_notification
    SmsNuntium.notify_sms users, message_notification 
  end
end
