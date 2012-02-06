require 'spec_helper'

describe Hash do
  it "fetches many keys" do
    hash = {:a => 1, :b => 2, :c => 3}
    hash.fetch_many(:a, :c).should eq([1, 3])
  end
end
