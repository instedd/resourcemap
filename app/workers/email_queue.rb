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

    message =  message.gsub(/\[[\w\s]+\]/) do |template|
      if template.match(/site\s?name/i) 
        site.name
      else
        getfieldvalue(template, site)
      end
    end
    
  end

  def self.getfieldvalue(template, site)
    site.properties.each do |property|
      field = Field.find(property[0])
      if template == '[' + field.name + ']'
        template = property[1] 
        break
      end
    end
    template
  end

end
