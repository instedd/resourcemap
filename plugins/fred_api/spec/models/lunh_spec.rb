require 'spec_helper'

describe "Luhn" do
  let(:field) { Field::IdentifierField::Luhn.new }

  context "validation" do
    it "fails if length is not eight" do
      lambda do
        field.apply_format_update_validation("1234", nil, nil)
      end.should raise_exception(RuntimeError, /nnnnnn/)
    end

    it "fails if not numeric" do
      lambda do
        field.apply_format_update_validation("abcef-g", nil, nil)
      end.should raise_exception(RuntimeError, /nnnnnn/)
    end

    it "fails if lunh check is not valid" do
      lambda do
        field.apply_format_update_validation("100000-8", nil, nil)
      end.should raise_exception(RuntimeError, /failed the lunh check/)
    end

    it "passes if the lunh check is valid" do
      field.apply_format_update_validation("100000-9", nil, nil)
    end

    it "fails if lunh check is not valid 2" do
      lambda do
        field.apply_format_update_validation("987654-6", nil, nil)
      end.should raise_exception(RuntimeError, /failed the lunh check/)
    end

    it "passes if the lunh check is valid 2" do
        field.apply_format_update_validation("987654-7", nil, nil)
    end
  end
end
