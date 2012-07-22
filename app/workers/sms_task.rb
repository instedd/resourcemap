class SmsTask
  @queue = :sms_queue
  def self.perform users_phone_number, message
    SmsNuntium.notify_sms users_phone_number, message
  end
end
