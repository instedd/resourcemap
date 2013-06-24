require 'spec_helper'

describe "Luhn" do
  let(:field) { Field::IdentifierField::Luhn.new(nil) }

  context "validation" do
    it "fails if length is not eight" do
      lambda do
        field.apply_format_save_validation("1234", nil, nil)
      end.should raise_exception(RuntimeError, /nnnnnn/)
    end

    it "fails if not numeric" do
      lambda do
        field.apply_format_save_validation("abcef-g", nil, nil)
      end.should raise_exception(RuntimeError, /nnnnnn/)
    end

    it "fails if luhn check is not valid" do
      lambda do
        field.apply_format_save_validation("100000-8", nil, nil)
      end.should raise_exception(RuntimeError, /failed the luhn check/)
    end

    it "passes if the luhn check is valid" do
      field.apply_format_save_validation("100000-9", nil, nil)
    end

    it "fails if luhn check is not valid 2" do
      lambda do
        field.apply_format_save_validation("987654-6", nil, nil)
      end.should raise_exception(RuntimeError, /failed the luhn check/)
    end

    it "passes if the luhn check is valid 2" do
      field.apply_format_save_validation("987654-7", nil, nil)
    end
  end

  it "generates luhn id for new site" do
    collection = Collection.make
    layer = collection.layers.make
    field = layer.identifier_fields.make config: {"context" => "MOH", "agency" => "DHIS", "format" => "Luhn"}

    collection.sites.make.properties[field.es_code].should eq("100000-9")
    collection.sites.make.properties[field.es_code].should eq("100001-8")
    collection.sites.make.properties[field.es_code].should eq("100002-7")
    collection.sites.make(properties: {field.es_code => "100004-5"}).properties[field.es_code].should eq("100004-5")
    collection.sites.make.properties[field.es_code].should eq("100003-6")
    collection.sites.make.properties[field.es_code].should eq("100005-4")
  end
end
