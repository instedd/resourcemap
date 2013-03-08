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
      expect { Site.parse_date(field.sample_value) }.to_not raise_error
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

    it "for hierarchy is a valid item" do
      config_hierarchy = [{ id: 0, name: 'root', sub: [{id: 1, name: 'child'}]}]
      field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
      # This isn't right: if you change the config_hierarchy, the next line has to be changed as well
      [0, 1].should include field.sample_value
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
    let!(:config_options) { [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}] }

    describe "select_many" do
      let!(:field) { Field::SelectManyField.make config: {options: config_options} }

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
      field.hierarchy_options.should eq([{:id=>0, :name=>"root"}, {:id=>1, :name=>"child"}])
    end

    it "for hierarchy with one level two childs" do
      config_hierarchy = [{ id: 0, name: 'root', sub: [{id: 1, name: 'child'}, {id: 2, name: 'child2'}]}]
      field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
      field.hierarchy_options.should eq([{:id=>0, :name=>"root"}, {:id=>1, :name=>"child"}, {:id=>2, :name=>"child2"}])
    end
  end

  describe "validations" do
    let!(:user) { User.make }
    let!(:collection) { user.create_collection Collection.make_unsaved }

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

    describe "apply_format_update_validation" do
      let!(:layer) { collection.layers.make }
      let!(:text) { layer.text_fields.make :code => 'text' }
      let!(:numeric) { layer.numeric_fields.make :code => 'numeric', :config => {} }
      let!(:yes_no) { layer.yes_no_fields.make :code => 'yes_no'}

      let!(:numeric_with_decimals) {
        layer.numeric_fields.make :code => 'numeric_with_decimals', :config => {
          :allows_decimals => "true" }.with_indifferent_access
        }

      let!(:select_one) { layer.select_one_fields.make :code => 'select_one', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }

      let!(:select_many) { layer.select_many_fields.make :code => 'select_many', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }

      config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
      let!(:hierarchy) { layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access }
      let!(:site_field) { layer.site_fields.make :code => 'site'}
      let!(:date) { layer.date_fields.make :code => 'date' }
      let!(:director) { layer.user_fields.make :code => 'user' }
      let!(:email_field) { layer.email_fields.make :code => 'email' }

      let!(:site) {collection.sites.make name: 'Foo old', id: 1234, properties: {} }

      it "should validate format for numeric field" do
        numeric.apply_format_update_validation(2, false, collection).should be(2)
        numeric.apply_format_update_validation("2", false, collection).should be(2)
        expect { numeric.apply_format_update_validation("invalid23", false, collection) }.to raise_error(RuntimeError, "Invalid numeric value in #{numeric.code} field")
      end

      it "should validate format for yes_no field" do
        yes_no.apply_format_update_validation(true, false, collection).should be_true
        yes_no.apply_format_update_validation(1, false, collection).should be_true
        yes_no.apply_format_update_validation("true", false, collection).should be_true
        yes_no.apply_format_update_validation("yes", false, collection).should be_true
        yes_no.apply_format_update_validation("1", false, collection).should be_true
        yes_no.apply_format_update_validation(0, false, collection).should be_false
        yes_no.apply_format_update_validation("0", false, collection).should be_false
        yes_no.apply_format_update_validation("false", false, collection).should be_false
      end

      it "should not allow decimals" do
        expect { numeric.apply_format_update_validation("2.3", false, collection) }.to raise_error(RuntimeError, "Invalid numeric value in #{numeric.code} field. This numeric field is configured not to allow decimal values.")

        expect { numeric.apply_format_update_validation(2.3, false, collection) }.to raise_error(RuntimeError, "Invalid numeric value in #{numeric.code} field. This numeric field is configured not to allow decimal values.")
      end

      it "should allow decimals" do
        numeric_with_decimals.apply_format_update_validation("2.3", false, collection).should == 2.3
        numeric_with_decimals.apply_format_update_validation(2.3, false, collection).should == 2.3
      end

      it "should validate format for date field" do
        date.apply_format_update_validation("11/27/2012", false, collection).should == "2012-11-27T00:00:00Z"
        expect { date.apply_format_update_validation("11/27", false, collection) }.to raise_error(RuntimeError, "Invalid date value in #{date.code} field")
        expect { date.apply_format_update_validation("invalid", false, collection) }.to raise_error(RuntimeError, "Invalid date value in #{date.code} field")
      end

      it "should validate format for hierarchy field" do
        hierarchy.apply_format_update_validation("101", false, collection).should == "101"
        expect { hierarchy.apply_format_update_validation("Dad", false, collection) }.to raise_error(RuntimeError, "Invalid option in #{hierarchy.code} field")
        expect { hierarchy.apply_format_update_validation("invalid", false, collection) }.to raise_error(RuntimeError, "Invalid option in #{hierarchy.code} field")
      end

      it "should validate format for select_one field" do
        select_one.apply_format_update_validation(1, false, collection).should == 1
        select_one.apply_format_update_validation("1", false, collection).should == "1"
        expect { select_one.apply_format_update_validation("one", false, collection) }.to raise_error(RuntimeError, "Invalid option in #{select_one.code} field")
        expect { select_one.apply_format_update_validation("invalid", false, collection) }.to raise_error(RuntimeError, "Invalid option in #{select_one.code} field")
      end

      it "should validate format for select_many field" do
        select_many.apply_format_update_validation([2], false, collection).should == [2]
        select_many.apply_format_update_validation(["2", "1"], false, collection).should == ["2", "1"]
        expect { select_many.apply_format_update_validation(["two",], false, collection) }.to raise_error(RuntimeError, "Invalid option in #{select_many.code} field")
        expect { select_many.apply_format_update_validation("invalid", false, collection) }.to raise_error(RuntimeError, "Invalid option in #{select_many.code} field")
      end

      it "should validate format for site field" do
        site_field.apply_format_update_validation(1234, false, collection).should == 1234
        site_field.apply_format_update_validation("1234", false, collection).should == "1234"
        expect { site_field.apply_format_update_validation(124, false, collection) }.to raise_error(RuntimeError, "Non-existent site-id in #{site_field.code} field")
        expect { site_field.apply_format_update_validation("124inv", false, collection) }.to raise_error(RuntimeError, "Non-existent site-id in #{site_field.code} field")
      end

      it "should validate format for user field" do
        director.apply_format_update_validation(user.email, false, collection).should == user.email
        expect { director.apply_format_update_validation("inexisting@email.com", false, collection) }.to raise_error(RuntimeError, "Non-existent user email address in #{director.code} field")
      end

      it "should validate format for email field" do
        email_field.apply_format_update_validation("valid@email.com", false, collection).should == "valid@email.com"
        expect { email_field.apply_format_update_validation("s@@email.c.om", false, collection) }.to raise_error(RuntimeError, "Invalid email address in #{email_field.code} field")
      end
    end
  end
end
