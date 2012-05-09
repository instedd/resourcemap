require 'spec_helper'

describe Site do
  it { should belong_to :collection }

  it "removes empty properties after save" do
    site = Site.make properties: {foo: 1, bar: nil, baz: 3}
    site.properties.should_not have_key(:bar)
  end
end
