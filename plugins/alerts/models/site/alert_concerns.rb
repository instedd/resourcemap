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
        phone_numbers = notification_numbers alert
        users_email = []
        users_email << User.find(alert.email_notification[:members]).map { |user| user.email} if alert.email_notification[:members]
        
        alert.email_notification.except(:members).values.flatten.each do |field|
          users_email << properties[field] 
        end
        
        message_notification = alert.message_notification.render_template_string(get_template_value_hash)
        Resque.enqueue SmsTask, phone_numbers, message_notification unless phone_numbers.empty?
        Resque.enqueue EmailTask, users_email.flatten.compact, message_notification, "[ResourceMap] Alert Notification" unless users_email.empty?
      end
    else
      extended_properties[:alert] = false
    end
    true
  end

  def notification_numbers(alert)
    phone_numbers = collection.users.where(id: alert.phone_notification[:members]).map(&:phone_number).reject &:blank?
    phone_numbers |= alert.phone_notification[:fields].to_a.map{|field| properties[field] }.reject &:blank?
    users = alert.phone_notification[:users].to_a.map{|field| properties[field] }.reject(&:blank?)
    phone_numbers |= User.where(email: users).map(&:phone_number).reject(&:blank?)
  end
end
