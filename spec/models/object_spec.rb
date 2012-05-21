require 'spec_helper'

describe Object do
  it "converts to_i with to_i_or_f" do
    "123".to_i_or_f.should eq(123)
  end

  it "converts to_f with to_i_or_f" do
    "123.4".to_i_or_f.should eq(123.4)
  end

  it "converts to nil with to_i_or_f" do
    "Hello".to_i_or_f.should be_nil
  end
end
