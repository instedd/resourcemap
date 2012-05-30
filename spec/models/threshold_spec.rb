require 'spec_helper'

describe Threshold do
  it { should belong_to :collection }
  it { should validate_presence_of(:ord) }
  it { should validate_presence_of(:color) }
  its(:conditions) { should eq([]) }

  let!(:collection) { Collection.make }
  let!(:layer) { collection.layers.make }
  let!(:beds) { layer.fields.make id: 123, code: 'beds', kind: 'numeric' }
  let!(:doctors) { layer.fields.make id: 124, code: 'doctors', kind: 'numeric' }

  it "should convert conditions' value to int if the field is int" do
    threshold = collection.thresholds.make conditions: [ field: beds.es_code, op: :lt, value: '10' ]
    threshold.conditions[0][:value].should eq(10)
  end

  [
    { field: '123', op: :lt, value: '10', property_value: 9 },
    { field: '123', op: :lte, value: '10', property_value: 10 },
    { field: '123', op: :gt, value: '10', property_value: 11 },
    { field: '123', op: :gte, value: '10', property_value: 10 },
    { field: '123', op: :eq, value: '10', property_value: 10 }
  ].each do |hash|
    it "should throw :threshold with #{hash[:op].to_s} condition" do
      threshold = collection.thresholds.make conditions: [ hash ]
      expect { threshold.test({ hash[:field] => hash[:property_value] }) }.to throw_symbol :threshold, true
    end
  end

  describe "multiple conditions" do
    let!(:threshold) { collection.thresholds.make conditions: [ {field: beds.es_code, op: :gt, value: '10'}, {field: doctors.es_code, op: :lte, value: '2'} ] }

    it "should throw :threshold when all conditions are matched" do
      expect { threshold.test({beds.es_code => 11, doctors.es_code => 2}) }.to throw_symbol :threshold, true
    end

    it "should not throw when one condition is not matched" do
      expect { threshold.test({beds.es_code => 9, doctors.es_code => 2}) }.to_not throw_symbol
      expect { threshold.test({beds.es_code => 11, doctors.es_code => 3}) }.to_not throw_symbol
    end

    it "should not throw when no condition is matched" do
      expect { threshold.test({beds.es_code => 9, doctors.es_code => 3}) }.to_not throw_symbol
    end
  end
end
