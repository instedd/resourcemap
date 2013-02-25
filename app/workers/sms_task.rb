class SmsTask
  @queue = :sms_queue
  def self.perform users_phone_number, message, suggested_channel, collection_id
    SmsNuntium.notify_sms users_phone_number, message, suggested_channel, collection_id
  end
end
