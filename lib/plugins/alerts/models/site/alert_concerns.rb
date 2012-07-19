module Site::AlertConcerns
  extend ActiveSupport::Concern

  included do
    before_save :set_alert
  end

  def set_alert
    alert = collection.thresholds_test properties, id unless self.is_a? SiteHistory
    if alert != nil
      extended_properties[:alert] = true
      extended_properties[:icon] = alert.icon
      if alert.is_notify
        users_phone_number = User.find(alert.phone_notification).map { |user| user.phone_number}
        users_email = User.find(alert.email_notification).map { |user| user.email}
        message_notification = alert.message_notification.render_template_string(get_template_value_hash)
        Resque.enqueue SmsTask, users_phone_number, message_notification unless users_phone_number.empty?
        Resque.enqueue EmailTask, users_email, message_notification, "[ResourceMap] Alert Notification" unless users_email.empty?
      end
    else
      extended_properties[:alert] = false
      extended_properties[:icon] = nil
    end
  end
end
