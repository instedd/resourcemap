require 'spec_helper'

describe "Luhn" do
  let(:collection) { Collection.make }
  let(:layer) { collection.layers.make }
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

    it "fails if numeric but chars follow" do
      lambda do
        field.apply_format_and_validate("100000-9asf", nil, collection)
      end.should raise_exception(RuntimeError, /nnnnnn/)
    end

    it "fails if luhn check is not valid" do
      lambda do
        field.apply_format_and_validate("108439-6", nil, collection)
      end.should raise_exception(RuntimeError, /Invalid Luhn check digit/)
    end

    it "passes if the luhn check is valid" do
      field.apply_format_and_validate("108439-1", nil, collection)
    end

    it "fails if luhn check is not valid 2" do
      lambda do
        field.apply_format_and_validate("987654-6", nil, collection)
      end.should raise_exception(RuntimeError, /Invalid Luhn check digit/)
    end

    it "passes if the luhn check is valid 2" do
      field.apply_format_and_validate("987654-1", nil, collection)
    end

    it "doesn't fail if blank" do
      field.apply_format_and_validate("", nil, collection)
    end
  end

  def create_site_and_assign_default_values(luhn_value)
    if luhn_value
      site = collection.sites.make(properties: {field.es_code => luhn_value})
    else
      site = collection.sites.make
    end

    site.assign_default_values_for_create
    site.save!
    site
  end

  it "generates luhn id for new site" do
    collection.sites.make
    create_site_and_assign_default_values(nil).properties[field.es_code].should eq("100000-9")
    create_site_and_assign_default_values(nil).properties[field.es_code].should eq("100001-7")
    create_site_and_assign_default_values(nil).properties[field.es_code].should eq("100002-5")
    create_site_and_assign_default_values("100004-1").properties[field.es_code].should eq("100004-1")
    create_site_and_assign_default_values(nil).properties[field.es_code].should eq("100005-8")
    create_site_and_assign_default_values(nil).properties[field.es_code].should eq("100006-6")
  end

  it "generates luhn id for new site after 000000-0" do
    collection.sites.make properties: {field.es_code => "000000-0"}
    create_site_and_assign_default_values(nil).properties[field.es_code].should eq("000001-8")
    create_site_and_assign_default_values(nil).properties[field.es_code].should eq("000002-6")
  end

  it "gets next luhn" do
    field.format_implementation.next_luhn("100006-6").should eq("100007-4")
    field.format_implementation.next_luhn("100007-4").should eq("100008-2")
    field.format_implementation.next_luhn("100009-2").should eq("100010-8")
    field.format_implementation.next_luhn("100010-8").should eq("100011-6")
  end

  it "checks for unicity" do
    create_site_and_assign_default_values(nil).properties[field.es_code].should eq("100000-9")
    lambda do
      collection.sites.make(properties: {field.es_code => "100000-9"})
    end.should raise_exception(ActiveRecord::RecordInvalid, /The value already exists in the collection/)
  end

  it "updates site" do
    site = collection.sites.make
    site.properties[field.es_code] = site.properties[field.es_code]
    site.save!
  end

  it "gets new site properties" do
    props = collection.new_site_properties
    props.length.should eq(1)
    props[field.es_code].should eq("100000-9")
  end

  it "do not search only in the first 50 when genetating values" do
    51.times do
      create_site_and_assign_default_values(nil)
    end
    lambda do
      create_site_and_assign_default_values(nil)
    end.should_not raise_exception(ActiveRecord::RecordInvalid, /The value already exists in the collection/)
  end


end
