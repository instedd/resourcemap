require 'spec_helper'

describe Layer do
  it { should belong_to :collection }
  it { should have_many :fields }
end
