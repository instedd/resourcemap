require 'spec_helper'

describe Site do
  it { should belong_to :collection }
  it { should belong_to :parent }
end
