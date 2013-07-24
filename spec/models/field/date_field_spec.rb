require 'spec_helper'

describe Field::DateField do

  describe "Default format" do
    it "should be created with mm/dd/yyyy format by default" do
      field = Field::DateField.make
      field.format_message().should eq "The configured date format is mm/dd/yyyy."
    end

    it "should be created with default format " do
      field = Field::DateField.make config: {format: "mm_dd_yyyy"}
      field.format_message().should eq "The configured date format is mm/dd/yyyy."
    end
  end

  describe "Format dd/mmm/yyyy" do
    let!(:field) { Field::DateField.make code: 'date', config: {format: "dd_mmm_yyyy"}.with_indifferent_access }

    it "should be created with dd/mmm/yyyy format" do
      field.format_message().should eq "The configured date format is dd/mmm/yyyy."
    end

    it "should fail in decoding invalid value" do
      expect { field.decode("08/Hey/2013") }.to raise_error(RuntimeError, "Invalid date value in field date. The configured date format is dd/mmm/yyyy.")
    end

    it "should decode valid value" do
      field.decode("26/Dec/1988").should eq("1988-12-26T00:00:00Z")
    end

  end
end
