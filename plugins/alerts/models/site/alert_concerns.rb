module Site::AlertConcerns
  extend ActiveSupport::Concern

  included do
    before_index :set_alert, if: ->(site) { site.collection.alerts_plugin_enabled? }
  end

  def set_alert
    alert = collection.thresholds_test self unless self.is_a? SiteHistory
    if alert != nil
      extended_properties[:alert] = true
      extended_properties[:icon] = alert.icon
      if alert.is_notify
        users_phone_number = []
        users_email = []
        users_phone_number << User.find(alert.phone_notification[:members]).map { |user| user.phone_number}
        users_email << User.find(alert.email_notification[:members]).map { |user| user.email}
        alert.email_notification.except(:members).values.flatten.each do |field|
          users_email << properties[field] 
        end
        
        alert.phone_notification[:fields].each do |field|
          users_phone_number << properties[field] 
        end
        
        alert.phone_notification[:users].each do |user|
          users_phone_number << User.find_all_by_email(properties[user]).map { |user| user.phone_number} # get users phone_number based on users_email
        end
        message_notification = alert.message_notification.render_template_string(get_template_value_hash)
        Resque.enqueue SmsTask, users_phone_number.flatten.compact, message_notification unless users_phone_number.empty?
        Resque.enqueue EmailTask, users_email.flatten.compact, message_notification, "[ResourceMap] Alert Notification" unless users_email.empty?
      end
    else
      extended_properties[:alert] = false
      extended_properties[:icon] = nil
    end
  end
end
