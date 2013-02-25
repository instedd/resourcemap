require 'spec_helper'

describe Message do
  context "new" do
    subject { Message.new }

    it { should be_invalid }
    it { should validate_presence_of(:guid) }
    it { should validate_presence_of(:body) }
    it { should validate_presence_of(:from) }
    its(:save) { should be_false }
  end

  describe "check message channel and sender" do
    before(:each) do
      @message =  Message.new
    end

    it "should not be an sms" do
      @message.should_not be_channel(:sms)
    end

    it "should not have a sender" do
      @message.sender.should be_nil
    end

    it "should check message is and sms" do
      @message.from = "sms://1"
      @message.should be_channel(:sms)
    end

    it "should find sender by phone number" do
      user = User.make :phone_number => "1"
      @message.from = "sms://1"
      @message.sender.should eq(user)
    end
  end

  describe "#process!" do
    before(:each) do
      collection = Collection.make :id => 1
      user = User.make :phone_number => '123'
      collection.memberships.create :user => user, :admin => true
      @message = Message.new :guid => '999', :from => 'sms://123', :body => 'dyrm q 1 beds>12'
    end

    it "should save reply" do
      @message.should_receive(:visit).and_return("done")
      @message.process!
      @message.reply.should == "done"
    end

    context "when command is invalid" do
      before(:each) do
        @message.body = "dyrm foo"
        @message.save
      end

      it "should not save reply" do
        lambda { @message.process! }.should raise_error(RuntimeError, "Invalid command")
        @message.reply.should be_nil
      end
    end
  end

  describe "visit command" do
    it "should accept ExecVisitor" do
      message = Message.create :guid => '999', :from => 'sms://123', :body => "foo"
      command = mock('Command')
      command.should_receive(:sender=)
      command.should_receive(:accept)
      # Execute
      message.visit command, nil
    end
  end

  describe "message log" do 
    let(:collection) { Collection.make quota: 10 } 
    it 'should change collection.quota after log  message' do
      expect{ 
        Message.log [{from: '123456', to: '123456', body: 'hello resourcemap'}], collection.id
      }.to change{
        c = Collection.find collection.id 
        c.quota
      }.from(10).to(9)
    end


    it "shouldn't change collection.quota after create new message with property is_send == false" do
      message = Message.new from: '123456', to: '123456', body: 'hello resourcemap', is_send: false, collection_id: collection.id
      c = Collection.find collection.id 
      c.quota.should eq collection.quota
    end

  end
end
