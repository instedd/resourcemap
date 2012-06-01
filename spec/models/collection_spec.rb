require 'spec_helper'
describe Collection do it { should validate_presence_of :name }
  it { should have_many :memberships }
  it { should have_many :users }
  it { should have_many :layers }
  it { should have_many :fields }
  it { should have_many :thresholds }

  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }
  let!(:layer) { collection.layers.make user: user, fields_attributes: [{kind: 'numeric', code: 'foo', name: 'Foo', ord: 1}] }
  let!(:field) { layer.fields.first }

  context "max value" do
    it "gets max value for property that exists" do
      collection.sites.make :properties => {field.es_code => 10}
      collection.sites.make :properties => {field.es_code => 20}, :lat => nil, :lng => nil
      collection.sites.make :properties => {field.es_code => 5}

      collection.max_value_of_property(field.es_code).should eq(20)
    end

    it "gets max value for property that doesn't exist" do
      collection.max_value_of_property(field.es_code).should eq(0)
    end
  end

  describe "thresholds test" do
    let!(:properties) { { field.es_code => 9 } }

    it "should return false when there is no threshold" do
      collection.thresholds_test(properties).should be_false
    end

    it "should return false when no threshold is hit" do
      collection.thresholds.make conditions: [ field: field.es_code, op: :gt, value: 10 ]
      collection.thresholds_test(properties).should be_false
    end

    it "should return true when threshold 1 is hit" do
      collection.thresholds.make conditions: [ field: field.es_code, op: :lt, value: 10 ]
      collection.thresholds_test(properties).should be_true
    end

    it "should return true when threshold 2 is hit" do
      collection.thresholds.make conditions: [ field: field.es_code, op: :gt, value: 10 ]
      collection.thresholds.make conditions: [ field: field.es_code, op: :eq, value: 9 ]
      collection.thresholds_test(properties).should be_true
    end
  end

  describe "SMS query" do
    it "should prepare response_sms" do 
      option = {:field_code => "AB", :field_id => 2}
      result = [{"_source"=>{"id"=>1, "name"=>"Siem Reap Health Center", "properties"=>{"1"=>15, "2"=>40, "3"=>6}}}] 
      collection.response_prepare(option[:field_code], option[:field_id], result).should eq("[\"#{option[:field_code]}\"] in #{[result[0]["_source"]["name"],40].join(", ")}")
    end 
    
    describe "Operator parser" do 
      it "should return operator for search class" do
        collection.operator_parser(">").should eq("gt")
        collection.operator_parser("<").should eq("lt")
        collection.operator_parser("=>").should eq("gte")
        collection.operator_parser("=<").should eq("lte")
        collection.operator_parser(">=").should eq("gte")
        collection.operator_parser("<=").should eq("lte")
      end
    end 

  end
end
