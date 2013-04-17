require 'mail'

Mail.defaults do
  retriever_method :pop3, { :address             => "pop.gmail.com",
                            :port                => 995,
                            :user_name           => 'testingstg@gmail.com',
                            :password            => '8c4mmha2',
                            :enable_ssl          => true }
end

module MailHelper
  def get_mail
    sleep 15
    internal_get_mail
  end

  def internal_get_mail
    mail = Mail.last
    mail = mail.first if mail.is_a? Array
    if mail
      if mail.html_part
        mail.html_part.body.to_s
      else
        mail.body.to_s
      end
    else
      nil
    end
  end
end
