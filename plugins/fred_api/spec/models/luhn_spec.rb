require 'spec_helper'

describe "Luhn" do
  let!(:collection) { Collection.make }
  let!(:layer) { collection.layers.make }
  let!(:field) { layer.identifier_fields.make config: {"context" => "MOH", "agency" => "DHIS", "format" => "Luhn"} }

  context "validation" do
    it "fails if length is not eight" do
      lambda do
        field.apply_format_and_validate("1234", nil, collection)
      end.should raise_exception(RuntimeError, /nnnnnn/)
    end

    it "fails if not numeric" do
      lambda do
        field.apply_format_and_validate("abcef-g", nil, collection)
      end.should raise_exception(RuntimeError, /nnnnnn/)
    end

    it "fails if luhn check is not valid" do
      lambda do
        field.apply_format_and_validate("100000-8", nil, collection)
      end.should raise_exception(RuntimeError, /failed the luhn check/)
    end

    it "passes if the luhn check is valid" do
      field.apply_format_and_validate("100000-9", nil, collection)
    end

    it "fails if luhn check is not valid 2" do
      lambda do
        field.apply_format_and_validate("987654-6", nil, collection)
      end.should raise_exception(RuntimeError, /failed the luhn check/)
    end

    it "passes if the luhn check is valid 2" do
      field.apply_format_and_validate("987654-7", nil, collection)
    end

    it "doesn't fail if blank" do
      field.apply_format_and_validate("", nil, collection)
    end
  end

  it "generates luhn id for new site" do
    collection.sites.make.properties[field.es_code].should eq("100000-9")
    collection.sites.make.properties[field.es_code].should eq("100001-8")
    collection.sites.make.properties[field.es_code].should eq("100002-7")
    collection.sites.make(properties: {field.es_code => "100004-5"}).properties[field.es_code].should eq("100004-5")
    collection.sites.make.properties[field.es_code].should eq("100003-6")
    collection.sites.make.properties[field.es_code].should eq("100005-4")
  end

  it "checks for unicity" do
    collection.sites.make.properties[field.es_code].should eq("100000-9")
    lambda do
      collection.sites.make(properties: {field.es_code => "100000-9"})
    end.should raise_exception(ActiveRecord::RecordInvalid, /the value already exists in the collection/)
  end

  it "updates site" do
    site = collection.sites.make
    site.properties[field.es_code] = site.properties[field.es_code]
    site.save!
  end
end
