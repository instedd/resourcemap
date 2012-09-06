require 'spec_helper'

describe Field do
  it { should belong_to :collection }
  it { should belong_to :layer }

  it_behaves_like "it includes History::Concern"

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

  describe "cast strongly type" do
    let!(:config_options) { [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}] }

    describe "select_many" do
      let!(:field) { Field.make kind: 'select_many', config: {options: config_options} }

      it "should convert value to integer" do
        field.strongly_type('1').should eq 1
        field.strongly_type('2').should eq 2
      end

      pending "should not convert value when option does not exist" do
        field.strongly_type('3').should eq 0
      end
    end
  end

  it "should have kind 'user'" do
    Field.make(kind: 'user').should be_valid
  end

  it "should have kind 'email'" do 
    Field.make(kind: 'email').should be_valid
  end

  describe "core field type" do
    subject { Field::Kinds - Field::PluginKinds.keys }

    it { should have(6).items }
    it { should include 'text' }
    it { should include 'numeric' }
    it { should include 'select_one' }
    it { should include 'select_many' }
    it { should include 'hierarchy' }
    it { should include 'user' }
  end
end
