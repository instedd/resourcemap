class EmailQueue
  @queue = :email_queue

  def self.perform(threshold_id, site_id)
    threshold = Threshold.find(threshold_id)
    site = Site.find(site_id)
    if threshold.is_notify
      ThresholdMailer.notify_email(render_message(threshold.message_notification, site), threshold.email_notification).deliver
    end
  end

  def self.render_message(message, site) 
    message.gsub(/\[[\w\s]+\]/) { |template|
      if template.match(/site\s?name/i) 
        template = site.name
      else
        site.properties.map do |property|
          field = Field.find(property[0])
          template = property[1] if template == '[' + field.name + ']'
        end
      end
    }
  end
end
