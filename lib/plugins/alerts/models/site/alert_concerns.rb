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
        users_sms = User.find alert.phone_notification
        users_email = User.find alert.email_notification
        message_notification = alert.message_notification.render_template_string(get_template_value_hash)
        Resque.enqueue SmsQueue, users_sms, message_notification unless users_sms.empty?
        Resque.enqueue EmailQueue, users_email, message_notification unless users_email.empty?
      end
    else
      extended_properties[:alert] = false
      extended_properties[:icon] = nil
    end
  end
end