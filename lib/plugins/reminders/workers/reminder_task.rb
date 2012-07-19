class ReminderTask
  def self.perform    
    users_email = []  
    users_phone_number = []
    Reminder.where("next_run <= ?", Time.now).includes(:collection).each do |reminder|
      reminder.save! 
      next unless reminder.collection.is_plugin_enabled? 'reminders'
      reminder.target_sites.each do |site|
        users_email << site.properties[site.collection.fields.select { |f| f.kind =='email'}.first.id.to_s]
        users_phone_number << site.properties[site.collection.fields.select { |f| f.kind =='phone'}.first.id.to_s]
      end
      message_reminder = reminder.reminder_message
      Resque.enqueue SmsTask, users_phone_number.compact, message_reminder unless users_phone_number.empty?
      Resque.enqueue EmailTask, users_email.compact, message_reminder, "[ResourceMap] Reminder Notification"  unless users_email.empty?
    end
  end
end
