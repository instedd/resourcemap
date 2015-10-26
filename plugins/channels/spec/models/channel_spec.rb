require 'spec_helper'
describe Channel, :type => :model do
  include_examples 'user lifespan', described_class, name: 'abcd'

  it { is_expected.to validate_presence_of :name }

  it 'should valid when name is more than 4 charracters' do
      channel = Channel.new name: 'abcd', password: '12345', advanced_setup: true
      expect(channel.valid?).to be_truthy
  end

  it 'should not valid when name is less than 4 characters' do
    channel = Channel.new name: "abc", password: "12345"
    expect(channel).not_to be_valid
  end

  describe 'when is advanced_setup == true' do
    before(:each) do
      @channel = Channel.new name: 'abcd', password: '', advanced_setup: true
    end

    it 'should require password' do
      expect(@channel.valid?).to be_falsey
    end

    it 'should require at least 4 character of password' do
      @channel.password = '123'
      expect(@channel.valid?).to be_falsey
    end

    it 'should be valid when password presence and more than 4 characters' do
      @channel.password = '12345'
      expect(@channel.valid?).to be_truthy
    end
  end

  describe 'when basic_setup == true' do
    before(:each) do
      @channel = Channel.new name: 'abcd', ticket_code: '', basic_setup: true
    end

    it 'should require ticket_code' do
      expect(@channel.valid?).to be_falsey
    end

    it 'should valid when ticket_code presence' do
      @channel.ticket_code = '1234'
      expect(@channel.valid?).to be_truthy
    end
  end
end
