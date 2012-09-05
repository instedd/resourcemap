class ReminderTask
  def self.perform
    Reminder.where("next_run <= ? && status = true", Time.now).includes(:collection).each do |reminder|
      reminder.save!
      next unless reminder.collection.plugin_enabled? 'reminders'
      users_email = []
      users_phone_number = []
      reminder.target_sites.each do |site|
        users_email << ReminderTask.get_site_properties_value_by_kind(site, 'email')
        users_phone_number << ReminderTask.get_site_properties_value_by_kind(site, 'phone')
      end
      message_reminder = reminder.reminder_message
      # to be refactoring 
      active_gateway =  reminder.collection.active_gateway
      suggested_channel = active_gateway.nil?? Channel.default_nuntium_name : active_gateway.nuntium_channel_name
      
      Resque.enqueue SmsTask, users_phone_number.flatten, message_reminder,suggested_channel unless users_phone_number.empty?
      Resque.enqueue EmailTask, users_email.flatten, message_reminder, "[ResourceMap] Reminder Notification"  unless users_email.empty?
    end
  end

  def self.get_site_properties_value_by_kind(site, kind)
    site.collection.fields.select { |f| f.kind == kind }.map{ |field| site.properties[field.id.to_s] }
  end
end
