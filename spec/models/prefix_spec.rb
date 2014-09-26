require 'spec_helper'

describe Prefix, :type => :model do
  it "should get first next prefix" do
    expect(Prefix.next.version).to eq("AA")
  end

  it "should get next prefix" do
    Prefix.create :version => 'AX'
    expect(Prefix.next.version).to eq('AY')
  end

  it "should save prefix after get next prefix" do
    expect {
      Prefix.next
    }.to change { Prefix.count }.by(1)
  end
end
