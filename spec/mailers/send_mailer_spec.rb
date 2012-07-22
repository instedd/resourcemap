require "spec_helper"

describe SendMailer do
  let!(:users) { [User.make, User.make]}
  let!(:message) {"testing"}
  let!(:mail) { SendMailer.notify_email([users[0].email, users[1].email], message, "email from resourcemap") }
  it "has email in queue" do 
    mail.deliver
    ActionMailer::Base.deliveries.empty?.should_not be_true
  end 
  it "send to correct email" do
    mail.deliver
    mail.to.should eq(users.map(&:email))
  end
  it "send a correct email" do
    mail.deliver
    mail.body.should eq(message)
  end

end
