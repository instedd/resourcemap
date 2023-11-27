require 'spec_helper'
require 'treetop_dependencies'

describe Message, :type => :model do
  include_examples 'collection lifespan', described_class, guid: '999', from: 'sms://123', body: "foo"

  context "new" do
    subject { Message.new }

    it { is_expected.to be_invalid }
    it { is_expected.to validate_presence_of(:guid) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_presence_of(:from) }

    describe '#save' do
      subject { super().save }
      it { is_expected.to be_falsey }
    end
  end

  describe "check message channel and sender" do
    before(:each) do
      @message =  Message.new
    end

    it "should not be an sms" do
      expect(@message).not_to be_channel(:sms)
    end

    it "should not have a sender" do
      expect(@message.sender).to be_nil
    end

    it "should check message is and sms" do
      @message.from = "sms://1"
      expect(@message).to be_channel(:sms)
    end

    it "should find sender by phone number" do
      user = User.make :phone_number => "1"
      @message.from = "sms://1"
      expect(@message.sender).to eq(user)
    end
  end

  describe "#process!" do
    before(:each) do
      collection = Collection.make
      user = User.make :phone_number => '123'
      collection.memberships.create :user => user, :admin => true
      @message = Message.new :guid => '999', :from => 'sms://123', :body => 'dyrm q 1 beds>12'
    end

    it "should save reply" do
      expect(@message).to receive(:visit).and_return("done")
      @message.process!
      expect(@message.reply).to eq("done")
    end

    context "when command is invalid" do
      before(:each) do
        @message.body = "dyrm foo"
        @message.save
      end

      it "should not save reply" do
        expect { @message.process! }.to raise_error(RuntimeError, "Invalid command")
        expect(@message.reply).to be_nil
      end
    end
  end

  describe "visit command" do
    it "should accept ExecVisitor" do
      message = Message.create :guid => '999', :from => 'sms://123', :body => "foo"
      command = double('Command')
      expect(command).to receive(:sender=)
      expect(command).to receive(:accept)
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
      expect(c.quota).to eq collection.quota
    end

  end
end
