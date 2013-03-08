require 'spec_helper'

describe Layer do
  it { should belong_to :collection }
  it { should have_many :fields }

  def history_concern_class
    described_class
  end

  def history_concern_foreign_key
    described_class.name.foreign_key
  end

  def history_concern_histories
    "#{described_class}_histories"
  end

  it_behaves_like "it includes History::Concern"
end
