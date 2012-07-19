class SmsNuntium
  def self.notify_sms users_phone_number, message
    nuntium_messages = []
    users_phone_number.each do |phone_number|
      nuntium_message = {
        :from =>"resourcemap", 
        :to => "sms://#{phone_number}", 
        :body => message, 
        :suggested_channel => "testing"
      }
      nuntium_messages.push nuntium_message
    end
    nuntium = Nuntium.new_from_config
    nuntium.send_ao nuntium_messages
  end
end
