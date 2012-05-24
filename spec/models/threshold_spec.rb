require 'spec_helper'

describe Threshold do
  it { should belong_to :collection }
  it { should validate_presence_of(:ord) }
  it { should validate_presence_of(:color) }
  its(:conditions) { should eq([]) }

  [
    { field: 'beds', is: :lt, value: 10, property_value: 9 },
    { field: 'beds', is: :lte, value: 10, property_value: 10 },
    { field: 'beds', is: :gt, value: 10, property_value: 11 },
    { field: 'beds', is: :gte, value: 10, property_value: 10 },
    { field: 'beds', is: :eq, value: 10, property_value: 10 }
  ].each do |hash|
    it "should throw :threshold with #{hash[:is].to_s} condition" do
      threshold = Threshold.make conditions: [ hash ]
      expect { threshold.test({ hash[:field] => hash[:property_value] }) }.to throw_symbol :threshold, true
    end
  end

  describe "multiple conditions" do
    let!(:threshold) { Threshold.make conditions: [ {field: 'beds', is: :gt, value: 10}, {field: 'doctors', is: :lte, value: 2} ] }

    it "should throw :threshold when all conditions are matched" do
      expect { threshold.test({'beds' => 11, 'doctors' => 2}) }.to throw_symbol :threshold, true
    end

    it "should not throw when one condition is not matched" do
      expect { threshold.test({'beds' => 9, 'doctors' => 2}) }.to_not throw_symbol
      expect { threshold.test({'beds' => 11, 'doctors' => 3}) }.to_not throw_symbol
    end

    it "should not throw when no condition is matched" do
      expect { threshold.test({'beds' => 9, 'doctors' => 3}) }.to_not throw_symbol
    end
  end
end
