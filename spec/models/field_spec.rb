require 'spec_helper'

describe Field do
  it { should belong_to :collection }
  it { should belong_to :layer }

  it "sanitizes options" do
    field = Field.make config: {options: [{code: 'foo', label: 'bar'}]}.with_indifferent_access
    field.config.class.should eq(Hash)
    field.config['options'].each do |option|
      option.class.should eq(Hash)
    end
  end

  it "sanitizes hierarchy" do
    field = Field.make config: {hierarchy: [{sub: [{}.with_indifferent_access]}]}.with_indifferent_access
    field.config.class.should eq(Hash)
    field.config['hierarchy'].each do |item|
      item.class.should eq(Hash)
      item['sub'].first.class.should eq(Hash)
    end
  end
end
