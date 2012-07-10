class ThresholdMailer < ActionMailer::Base
  default from: "noreply@resourcemap.instedd.org"

  def notify_email(users, message_notification)
    emails = users.map {|user| user["email"]}
    mail(:to => emails, :subject => "[ResourceMap] Alert Notification") do |format|
      format.text {render :text => message_notification}
    end
  end
end
