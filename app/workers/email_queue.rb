class EmailQueue
  @queue = :email_queue

  def self.perform(threshold_id, site_id)
    threshold = Threshold.find(threshold_id)
    site = Site.find(site_id)
    if threshold.is_notify
      option_hash = site.get_field_value_hash
      option_hash["site name"] = site.name
      ThresholdMailer.notify_email(
        threshold.message_notification.render_template_string(option_hash),
        threshold.email_notification).deliver
    end
  end
end
