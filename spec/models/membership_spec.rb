require 'spec_helper'

describe Membership do
  it { should belong_to :user }
  it { should belong_to :collection }
end
