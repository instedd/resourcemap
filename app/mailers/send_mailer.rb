class SendMailer < ActionMailer::Base
  default from: "noreply@resourcemap.instedd.org"

  def notify_email(users_email, message, email_subject)
    mail(:to => users_email, :subject => email_subject) do |format|
      format.text {render :text => message}
    end
  end
end
