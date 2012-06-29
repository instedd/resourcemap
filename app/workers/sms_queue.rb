class SmsQueue
  @queue = :sms_queue
  def self.perform users, message_notification
    messages = []
    users.each do |user|
      message = {
        :from =>"resourcemap", 
        :to => "sms://#{user["phone_number"]}", 
        :body => message_notification, 
        :suggested_channel => "testing"
      }
      messages.push message 
    end
    nuntium = Nuntium.new_from_config
    nuntium.send_ao messages
  end
end
