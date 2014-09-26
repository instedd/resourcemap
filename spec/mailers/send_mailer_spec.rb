require "spec_helper"

describe SendMailer, :type => :mailer do
  let(:users) { [User.make, User.make]}
  let(:message) {"testing"}
  let(:mail) { SendMailer.notify_email([users[0].email, users[1].email], message, "email from resourcemap") }
  it "has email in queue" do
    mail.deliver
    expect(ActionMailer::Base.deliveries.empty?).not_to be_truthy
  end
  it "send to correct email" do
    mail.deliver
    expect(mail.to).to eq(users.map(&:email))
  end
  it "send a correct email" do
    mail.deliver
    expect(mail.body).to eq(message)
  end

end
