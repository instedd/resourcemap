require 'spec_helper'

describe Site do
  it { should belong_to :collection }

  it_behaves_like "it includes History::Concern"
end
