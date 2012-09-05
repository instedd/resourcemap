class SmsTask
  @queue = :sms_queue
  def self.perform users_phone_number, message, suggested_channel
    SmsNuntium.notify_sms users_phone_number, message, suggested_channel
  end
end
