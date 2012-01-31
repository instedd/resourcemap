require 'spec_helper'

describe Field do
  it { should belong_to :collection }
  it { should belong_to :layer }
end
