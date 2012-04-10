require 'spec_helper'

describe Threshold do
  it { should belong_to :collection }
  it { should validate_presence_of(:priority) }
  it { should validate_presence_of(:color) }
end
