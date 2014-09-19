require 'spec_helper'

describe Field do
  def history_concern_class
    Field::TextField
  end

  def history_concern_foreign_key
    'field_id'
  end

  def history_concern_histories
    'field_histories'
  end

  def history_concern_class_foreign_key
    'field_id'
  end

  it_behaves_like "it includes History::Concern"

  it "sanitizes options" do
    field = Field::SelectOneField.make config: {options: [{code: 'foo', label: 'bar'}]}.with_indifferent_access
    field.config.class.should eq(Hash)
    field.config['options'].each do |option|
      option.class.should eq(Hash)
    end
  end

  it "sanitizes hierarchy" do
    field = Field::HierarchyField.make config: {hierarchy: [{sub: [{}.with_indifferent_access]}]}.with_indifferent_access
    field.config.class.should eq(Hash)
    field.config['hierarchy'].each do |item|
      item.class.should eq(Hash)
      item['sub'].first.class.should eq(Hash)
    end
  end

  it 'should include kind in json' do
    field = Field::SelectOneField.make config: {options: [{code: 'foo', label: 'bar'}]}.with_indifferent_access
    json = JSON.parse field.to_json
    json["kind"].should eq('select_one')
  end

  it "should return descendants_of_in_hierarchy" do
    config_hierarchy = [{ id: '0', name: 'root', sub: [{id: '1', name: 'child'}, {id: '2', name: 'child2'}]}]
    field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
    field.descendants_of_in_hierarchy('0').should eq(['0', '1', '2'])
    field.descendants_of_in_hierarchy('root').should eq(['0', '1', '2'])
  end

  it "should calculate max height of the hierarchy" do
    config_hierarchy = [{ id: '0', name: 'root', sub: [{id: '1', name: 'child'}, {id: '2', name: 'child2'}]}]
    field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
    field.hierarchy_max_height.should eq(2)

    config_hierarchy = [{ id: '0', name: 'root'}]
    field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
    field.hierarchy_max_height.should eq(1)

    config_hierarchy = [{ id: '0', name: 'root', sub: [{id: '1', name: 'child', sub:[{id: '3', name: 'child3'}] }, {id: '2', name: 'child2'}]}]
    field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
    field.hierarchy_max_height.should eq(3)
  end

  pending "descendants_of_in_hierarchy should return every results if option name is duplicated " do
    config_hierarchy = [{ id: '0', name: 'root', sub: [{id: '1', name: 'child'}]}, {id: '2', name: 'root'}]
    field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
    field.descendants_of_in_hierarchy('root').should eq(['0', '1', '2'])
  end

  it "should return ascendant_of_in_hierarchy" do
    config_hierarchy = [
      { id: '0', name: 'root', type: 'region', sub: [
        {id: '1', name: 'child', type: 'district', sub: [
          {id: '2', name: 'grand-child 2', type: 'ward'},
          {id: '4', name: 'grand-brother', type: 'ward'}
        ]}
      ]},
      {id: '3', name: "other", type: 'region'}
    ]

    field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
    res = [{:id=>"2", :name=>"grand-child 2", :type=>"ward"}, {:id=>"1", :name=>"child", :type=>"district"}, {:id=>"0", :name=>"root", :type=>"region"}]
    field.ascendants_of_in_hierarchy('2').should eq(res)
    field.ascendants_of_in_hierarchy('grand-child 2').should eq(res)
  end

  it "should return ascendants by type" do
    config_hierarchy = [
      { id: '0', name: 'root', type: 'region', sub: [
        {id: '1', name: 'child', type: 'district', sub: [
          {id: '2', name: 'grand-child 2', type: 'ward'},
          {id: '4', name: 'grand-brother', type: 'ward'}
        ]}
      ]},
      {id: '3', name: "other", type: 'region'}
    ]

    field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
    res = [{:id=>"2", :name=>"grand-child 2", :type=>"ward"}, {:id=>"1", :name=>"child", :type=>"district"}, {:id=>"0", :name=>"root", :type=>"region"}]
    field.ascendants_with_type('2', "district").should eq({:id=>"1", :name=>"child", :type=>"district"})
    field.ascendants_with_type('grand-child 2', "district").should eq({:id=>"1", :name=>"child", :type=>"district"})

    field.ascendants_with_type('grand-child 2', "not_found").should eq(nil)

  end

  it "should return ascendants by type if cache_for_read is enabled" do
    config_hierarchy = [
      { id: '0', name: 'root', type: 'region', sub: [
        {id: '1', name: 'child', type: 'district', sub: [
          {id: '2', name: 'grand-child 2', type: 'ward'},
          {id: '4', name: 'grand-brother', type: 'ward'}
        ]}
      ]},
      {id: '3', name: "other", type: 'region'}
    ]

    field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
    field.cache_for_read
    res = [{:id=>"2", :name=>"grand-child 2", :type=>"ward"}, {:id=>"1", :name=>"child", :type=>"district"}, {:id=>"0", :name=>"root", :type=>"region"}]
    field.ascendants_with_type('2', "district").should eq({:id=>"1", :name=>"child", :type=>"district"})
    field.ascendants_with_type('grand-child 2', "district").should eq({:id=>"1", :name=>"child", :type=>"district"})

    field.ascendants_with_type('grand-child 2', "not_found").should eq(nil)
  end

  describe "sample value" do
    it "for text are strings" do
      field = Field::TextField.make
      field.sample_value.should be_an_instance_of String
      field.sample_value.length.should be > 0
    end

    it "for numbers is a number" do
      field = Field::NumericField.make
      field.sample_value.should be_a_kind_of Numeric
    end

    it "for dates is a date" do
      field = Field::DateField.make
      expect { field.parse_date(field.sample_value) }.to_not raise_error
    end

    it "for user is a string" do
      user = User.make email: 'an@email.com'
      field = Field::UserField.make
      field.sample_value(user).should == (user.email)
    end

    it "for 'select one' is one of the choices" do
      config_options = [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}]
      field = Field::SelectOneField.make config: { options: config_options }.with_indifferent_access
      codes = config_options.map { |o| o[:code] }
      codes.should include field.sample_value
    end

    it "for 'select many' are among the choices" do
      config_options = [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}, {id: 3, code: 'three', label: 'Three'}]
      field = Field::SelectManyField.make config: { options: config_options }.with_indifferent_access
      codes = config_options.map { |o| o[:code] }
      field.sample_value.length.should be > 0
      field.sample_value.each do |option|
        codes.should include option
      end
    end

    it "for hierarchy is a valid item( a hierarchy id)" do
      config_hierarchy = [{ id: '0', name: 'root', sub: [{id: '1', name: 'child'}]}]
      field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
      ['0', '1'].should include field.sample_value
    end

    it "for email and phone is a string" do
      field = Field::EmailField.make
      field.sample_value.should be_an_instance_of String

      field = Field::PhoneField.make
      field.sample_value.should be_an_instance_of String
    end

    it "for fields with no config should be the empty string" do
      field = Field::SelectManyField.make config: {}
      field.sample_value.should == ''

      field = Field::SelectOneField.make config: {}
      field.sample_value.should == ''

      field = Field::HierarchyField.make config: {}
      field.sample_value.should == ''
    end
  end

  describe "cast strongly type" do
    let(:config_options) { [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}] }

    describe "select_many" do
      let(:field) { Field::SelectManyField.make config: {options: config_options} }

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
    Field::UserField.make.should be_valid
  end

  it "should have kind 'email'" do
    Field::EmailField.make.should be_valid
  end

  describe "generate hierarchy options" do
    it "for empty hierarchy" do
      config_hierarchy = []
      field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
      field.hierarchy_options.should eq([])
    end

    it "for hierarchy with one level" do
      config_hierarchy = [{ id: 0, name: 'root', sub: [{id: 1, name: 'child'}]}]
      field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
      field.hierarchy_options.should eq([{:id=>0, :name=>"root", :parent_id => ""}, {:id=>1, :name=>"child", :parent_id => 0}])
    end

    it "for hierarchy with one level two childs" do
      config_hierarchy = [{ id: 0, name: 'root', sub: [{id: 1, name: 'child'}, {id: 2, name: 'child2'}]}]
      field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
      field.hierarchy_options.should eq([{:id=>0, :name=>"root", :parent_id => ""}, {:id=>1, :name=>"child", :parent_id => 0}, {:id=>2, :name=>"child2", :parent_id => 0}])
    end
  end

  it "should download hierarchy as csv" do
    config_hierarchy = [{ id: 0, name: 'root', sub: [{id: 1, name: 'child', sub: [{id: 3, name: 'grand child'}]}, {id: 2, name: 'child2'}]}]
    field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
    csv =  CSV.parse(field.hierarchy_to_csv)
    csv[0].should eq(['ID', 'ParentID', 'ItemName'])
    csv[1].should eq(['0', '', 'root'])
    csv[2].should eq(['1', '0', 'child'])
    csv[3].should eq(['3', '1', 'grand child'])
    csv[4].should eq(['2', '0', 'child2'])
  end

  describe "validations" do
    let(:user) { User.make }
    let(:collection) { user.create_collection Collection.make_unsaved }
    let(:layer) { collection.layers.make }
    let(:text) { layer.text_fields.make :code => 'text' }
    let(:numeric) { layer.numeric_fields.make :code => 'numeric', :config => {} }
    let(:yes_no) { layer.yes_no_fields.make :code => 'yes_no'}

    let(:numeric_with_decimals) {
      layer.numeric_fields.make :code => 'numeric_with_decimals', :config => {
        :allows_decimals => "true" }.with_indifferent_access
      }

    let(:select_one) { layer.select_one_fields.make :code => 'select_one', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }

    let(:select_many) { layer.select_many_fields.make :code => 'select_many', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }

    config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
    let(:hierarchy) { layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access }
    let(:site_field) { layer.site_fields.make :code => 'site'}
    let(:date) { layer.date_fields.make :code => 'date' }
    let(:director) { layer.user_fields.make :code => 'user' }
    let(:email_field) { layer.email_fields.make :code => 'email' }

    let!(:site) {collection.sites.make name: 'Foo old', id: 1234, properties: {} }

    ['name', 'code'].each do |parameter|
      it "should validate uniqueness of #{parameter} in collection" do
        beds = collection.text_fields.make parameter.to_sym => 'beds'
        beds2 = collection.text_fields.make_unsaved parameter.to_sym => 'beds'

        beds2.should_not be_valid

        collection2 = Collection.make

        beds3 = collection2.text_fields.make_unsaved parameter.to_sym => 'beds'
        beds3.should be_valid
      end
    end

    it "validations for each field" do

      numeric.valid_value?(1).should be_true
      numeric.valid_value?("1").should be_true

      numeric_with_decimals.valid_value?(1.5).should be_true
      numeric_with_decimals.valid_value?("1.5").should be_true

      yes_no.valid_value?(true).should be_true
      yes_no.valid_value?(false).should be_true

      date.valid_value?("2012-11-27T00:00:00Z").should be_true

      hierarchy.valid_value?("101").should be_true

      select_many.valid_value?([1,2]).should be_true
      select_many.valid_value?(["1","2"]).should be_true

      select_one.valid_value?(1).should be_true
      select_one.valid_value?("1").should be_true

      site_field.valid_value?(1234).should be_true
      site_field.valid_value?("1234").should be_true

      director.valid_value?(user.email).should be_true

      email_field.valid_value?("myemail@resourcemap.com").should be_true
    end

    it "decode from ImportWizard format" do

      numeric.decode(1).should eq(1)
      numeric.decode("1").should eq(1)

      numeric_with_decimals.decode("1.5").should eq(1.5)

      yes_no.decode("true").should eq(true)

      date.decode("12/26/1988").should eq("1988-12-26T00:00:00Z")

      hierarchy.decode("Dad").should eq("60")

      select_one.decode("one").should eq(1)
      select_one.decode("One").should eq(1)

      select_many.decode("one").should eq([1])
      select_many.decode("One").should eq([1])
      select_many.decode(['one', 'two']).should eq([1, 2])
      select_many.decode("one,two").should eq([1, 2])

    end

    # TODO: Delete apply_format_and_validate method and use it's content instead with the corresponding decode
    # decode_fred or decode (for import_wizard)
    describe "apply_format_and_validate" do

      it "should validate format for numeric field" do
        numeric.apply_format_and_validate(2, false, collection).should be(2)
        numeric.apply_format_and_validate("2", false, collection).should be(2)
        expect { numeric.apply_format_and_validate("invalid23", false, collection) }.to raise_error(RuntimeError, "Invalid numeric value in field numeric. This numeric field is configured not to allow decimal values.")
      end

      it "should validate format for yes_no field" do
        yes_no.apply_format_and_validate(true, false, collection).should be_true
        yes_no.apply_format_and_validate(1, false, collection).should be_true
        yes_no.apply_format_and_validate("true", false, collection).should be_true
        yes_no.apply_format_and_validate("yes", false, collection).should be_true
        yes_no.apply_format_and_validate("1", false, collection).should be_true
        yes_no.apply_format_and_validate(0, false, collection).should be_false
        yes_no.apply_format_and_validate("0", false, collection).should be_false
        yes_no.apply_format_and_validate("false", false, collection).should be_false
      end

      it "should not allow decimals" do
        expect { numeric.apply_format_and_validate("2.3", false, collection) }.to raise_error(RuntimeError, "Invalid numeric value in field #{numeric.code}. This numeric field is configured not to allow decimal values.")
        expect { numeric.apply_format_and_validate(2.3, false, collection) }.to raise_error(RuntimeError, "Invalid numeric value in field #{numeric.code}. This numeric field is configured not to allow decimal values.")
      end

      it "should allow decimals" do
        numeric_with_decimals.apply_format_and_validate("2.3", false, collection).should == 2.3
        numeric_with_decimals.apply_format_and_validate(2.3, false, collection).should == 2.3
      end

      it "should validate format for date field" do
        date.apply_format_and_validate("11/27/2012",false, collection).should == "2012-11-27T00:00:00Z"
        expect { date.apply_format_and_validate("27/10/1298", false, collection) }.to raise_error(RuntimeError, "Invalid date value in field #{date.code}. The configured date format is mm/dd/yyyy.")
        expect { date.apply_format_and_validate("11/27", false, collection) }.to raise_error(RuntimeError, "Invalid date value in field #{date.code}. The configured date format is mm/dd/yyyy.")
        expect { date.apply_format_and_validate("invalid", false, collection) }.to raise_error(RuntimeError, "Invalid date value in field #{date.code}. The configured date format is mm/dd/yyyy.")
      end

      it "should validate format for hierarchy field" do
        hierarchy.apply_format_and_validate("Dad", false, collection).should == "60"
        expect { hierarchy.apply_format_and_validate("invalid", false, collection) }.to raise_error(RuntimeError, "Invalid hierarchy option 'invalid' in field 'hierarchy'")
      end

      it "should validate format for select_one field" do
        select_one.apply_format_and_validate("one", false, collection).should == 1
        select_one.apply_format_and_validate("One", false, collection).should == 1
        expect { select_one.apply_format_and_validate("invalid", false, collection) }.to raise_error(RuntimeError, "Invalid option in field #{select_one.code}")
      end

      it "should validate format for select_many field" do
        select_many.apply_format_and_validate(["two", "one"], false, collection).should == [2, 1]
        expect { select_many.apply_format_and_validate(["two","inv"], false, collection) }.to raise_error(RuntimeError, "Invalid option 'inv' in field #{select_many.code}")
        expect { select_many.apply_format_and_validate("invalid", false, collection) }.to raise_error(RuntimeError, "Invalid option 'invalid' in field #{select_many.code}")
      end

      it "should validate format for site field" do
        site_field.apply_format_and_validate(1234, false, collection).should == 1234
        site_field.apply_format_and_validate("1234", false, collection).should == "1234"
        expect { site_field.apply_format_and_validate(124, false, collection) }.to raise_error(RuntimeError, "Non-existent site-id in field #{site_field.code}")
        expect { site_field.apply_format_and_validate("124inv", false, collection) }.to raise_error(RuntimeError, "Non-existent site-id in field #{site_field.code}")
      end

      it "should validate format for user field" do
        director.apply_format_and_validate(user.email, false, collection).should == user.email
        expect { director.apply_format_and_validate("inexisting@email.com", false, collection) }.to raise_error(RuntimeError, "Non-existent user email address in field #{director.code}")
      end

      it "should validate format for email field" do
        email_field.apply_format_and_validate("valid@email.com", false, collection).should == "valid@email.com"
        expect { email_field.apply_format_and_validate("s@@email.c.om", false, collection) }.to raise_error(RuntimeError, "Invalid email address in field #{email_field.code}")
      end
    end
  end

  it "standardizes yes_no field" do
    field = Field::YesNoField.new
    field.standardize("true").should be_true
    field.standardize("false").should be_false
    field.standardize(true).should be_true
    field.standardize(false).should be_false
  end
end
