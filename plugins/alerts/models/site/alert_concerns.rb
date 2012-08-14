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
        emails = notification_emails alert
        message_notification = alert.message_notification.render_template_string(get_template_value_hash)

        Resque.enqueue SmsTask, phone_numbers, message_notification unless phone_numbers.empty?
        Resque.enqueue EmailTask, emails, message_notification, "[ResourceMap] Alert Notification" unless emails.empty?
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

  def notification_emails(alert)
    emails = collection.users.where(id: alert.email_notification[:members]).map(&:email).reject &:blank?
    emails |= alert.email_notification[:fields].to_a.map{|field| properties[field] }.reject &:blank?
    emails |= alert.email_notification[:users].to_a.map{|field| properties[field] }.reject(&:blank?)
  end
end
