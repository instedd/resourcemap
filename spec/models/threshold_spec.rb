require 'spec_helper'

describe Threshold do
  it { should belong_to :collection }
  it { should validate_presence_of(:priority) }
  it { should validate_presence_of(:color) }

  [
    { field: 'beds', is: :lt, value: 10, property_value: 9 },
    { field: 'beds', is: :lte, value: 10, property_value: 10 },
    { field: 'beds', is: :gt, value: 10, property_value: 11 },
    { field: 'beds', is: :gte, value: 10, property_value: 10 },
    { field: 'beds', is: :eq, value: 10, property_value: 10 }
  ].each do |hash|
    it "should throw :threshold with #{hash[:is].to_s} condition" do
      threshold = Threshold.make condition: [ hash ]
      expect { threshold.test({ hash[:field] => hash[:property_value] }) }.to throw_symbol :threshold, true
    end
  end
end
