class SmsNuntium
  def self.notify_sms users_phone_number, message, suggested_channel, collection_id
    nuntium_messages = []
    users_phone_number.each do |phone_number|
      nuntium_message = {
        :from =>"resourcemap", 
        :to => "sms://#{phone_number}", 
        :body => message, 
        :suggested_channel => suggested_channel
      }
      nuntium_messages.push nuntium_message
    end
    nuntium = Nuntium.new_from_config
    nuntium.send_ao nuntium_messages
    Message.log nuntium_messages, collection_id if collection_id
  end
end
