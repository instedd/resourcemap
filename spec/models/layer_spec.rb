require 'spec_helper'

describe Layer do
  it { should belong_to :collection }
  it { should have_many :fields }

  def history_concern_class
    described_class
  end

  it_behaves_like "it includes History::Concern"
end
