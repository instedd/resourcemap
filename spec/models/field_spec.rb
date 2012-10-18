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

  describe "sample value" do
    it "for text are strings" do
      field = Field.make kind: 'text'
      field.sample_value.should be_an_instance_of String
      field.sample_value.length.should be > 0
    end

    it "for numbers is a number" do
      field = Field.make kind: 'numeric'
      field.sample_value.should be_a_kind_of Numeric
    end

    it "for dates is a date" do
      field = Field.make kind: 'date'
      expect { Time.strptime field.sample_value, '%m/%d/%Y' }.to_not raise_error
    end

    it "for user is a string" do
      user = User.make email: 'an@email.com'
      field = Field.make kind: 'user'
      field.sample_value(user).should == (user.email)
    end

    it "for 'select one' is one of the choices" do
      config_options = [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}]
      field = Field.make kind: 'select_one', config: { options: config_options }.with_indifferent_access
      codes = config_options.map { |o| o[:code] }
      codes.should include field.sample_value
    end

    it "for 'select many' are among the choices" do
      config_options = [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}, {id: 3, code: 'three', label: 'Three'}]
      field = Field.make kind: 'select_many', config: { options: config_options }.with_indifferent_access
      codes = config_options.map { |o| o[:code] }
      field.sample_value.length.should be > 0
      field.sample_value.each do |option|
        codes.should include option
      end
    end

    it "for hierarchy is a valid item" do
      config_hierarchy = [{ id: 0, name: 'root', sub: [{id: 1, name: 'child'}]}]
      field = Field.make kind: 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access
      # This isn't right: if you change the config_hierarchy, the next line has to be changed as well
      [0, 1].should include field.sample_value
    end

    it "for email and phone is a string" do
      field = Field.make kind: 'email'
      field.sample_value.should be_an_instance_of String

      field = Field.make kind: 'phone'
      field.sample_value.should be_an_instance_of String
    end

    it "for fields with no config should be the empty string" do
      field = Field.make kind: 'select_many', config: {}
      field.sample_value.should == ''

      field = Field.make kind: 'select_one', config: {}
      field.sample_value.should == ''

      field = Field.make kind: 'hierarchy', config: {}
      field.sample_value.should == ''
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

    it { should have(8).items }
    it { should include 'text' }
    it { should include 'numeric' }
    it { should include 'select_one' }
    it { should include 'select_many' }
    it { should include 'hierarchy' }
    it { should include 'user' }
    it { should include 'date' }
    it { should include 'site' }

  end
end
