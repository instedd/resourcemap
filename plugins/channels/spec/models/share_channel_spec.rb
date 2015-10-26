require 'spec_helper'

describe ShareChannel, :type => :model do
  include_examples 'collection lifespan', described_class
end
