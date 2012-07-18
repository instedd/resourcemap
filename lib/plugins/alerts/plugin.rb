class Alerts::Plugin < Plugin

  collection_tab '/alerts_tab'

  site_index do |site, hash|
    alert = site.collection.thresholds_test site.properties, site.id unless site.is_a? SiteHistory
    if alert != nil
      hash[:alert] = true
      hash[:icon] = alert.icon
      if  alert.is_notify
        users_sms = User.find alert.phone_notification
        users_email = User.find alert.email_notification
        message_notification = alert.message_notification.render_template_string(site.get_template_value_hash)
        Resque.enqueue SmsQueue, users_sms, message_notification if(!users_sms.empty?)
        Resque.enqueue EmailQueue, users_email, message_notification if(!users_email.empty?)
      end
    else
      hash[:alert] = false
      hash[:icon] = nil
    end
  end

  field_type \
    name: 'user',
    css_class: 'luser',
    edit_view: 'fields/user_edit_view'

  field_type \
    name: 'email',
    css_class: 'lmessage',
    edit_view: 'fields/email_edit_view'

  routes {
    resources :collections do
      resources :thresholds do
        member do
          post :set_order
        end
      end
    end
  }
end
