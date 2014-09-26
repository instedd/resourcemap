require 'spec_helper'

describe Object, :type => :model do
  it "converts to_i with to_i_or_f" do
    expect("123".to_i_or_f).to eq(123)
  end

  it "converts to_f with to_i_or_f" do
    expect("123.4".to_i_or_f).to eq(123.4)
  end

  it "converts to nil with to_i_or_f" do
    expect("Hello".to_i_or_f).to be_nil
  end
end
