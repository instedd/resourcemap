require 'spec_helper'

describe "Luhn", :type => :model do
  let(:collection) { Collection.make }
  let(:layer) { collection.layers.make }
  let!(:field) { layer.identifier_fields.make config: {"context" => "MOH", "agency" => "DHIS", "format" => "Luhn"} }

  context "validation" do
    it "fails if length is not eight" do
      expect do
        field.apply_format_and_validate("1234", nil, collection)
      end.to raise_exception(RuntimeError, /nnnnnn/)
    end

    it "fails if not numeric" do
      expect do
        field.apply_format_and_validate("abcef-g", nil, collection)
      end.to raise_exception(RuntimeError, /nnnnnn/)
    end

    it "fails if numeric but chars follow" do
      expect do
        field.apply_format_and_validate("100000-9asf", nil, collection)
      end.to raise_exception(RuntimeError, /nnnnnn/)
    end

    it "fails if luhn check is not valid" do
      expect do
        field.apply_format_and_validate("108439-6", nil, collection)
      end.to raise_exception(RuntimeError, /Invalid Luhn check digit/)
    end

    it "passes if the luhn check is valid" do
      field.apply_format_and_validate("108439-1", nil, collection)
    end

    it "fails if luhn check is not valid 2" do
      expect do
        field.apply_format_and_validate("987654-6", nil, collection)
      end.to raise_exception(RuntimeError, /Invalid Luhn check digit/)
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
    expect(create_site_and_assign_default_values(nil).properties[field.es_code]).to eq("100000-9")
    expect(create_site_and_assign_default_values(nil).properties[field.es_code]).to eq("100001-7")
    expect(create_site_and_assign_default_values(nil).properties[field.es_code]).to eq("100002-5")
    expect(create_site_and_assign_default_values("100004-1").properties[field.es_code]).to eq("100004-1")
    expect(create_site_and_assign_default_values(nil).properties[field.es_code]).to eq("100005-8")
    expect(create_site_and_assign_default_values(nil).properties[field.es_code]).to eq("100006-6")
  end

  it "generates luhn id for new site after 000000-0" do
    collection.sites.make properties: {field.es_code => "000000-0"}
    expect(create_site_and_assign_default_values(nil).properties[field.es_code]).to eq("000001-8")
    expect(create_site_and_assign_default_values(nil).properties[field.es_code]).to eq("000002-6")
  end

  it "gets next luhn" do
    expect(field.format_implementation.next_luhn("100006-6")).to eq("100007-4")
    expect(field.format_implementation.next_luhn("100007-4")).to eq("100008-2")
    expect(field.format_implementation.next_luhn("100009-2")).to eq("100010-8")
    expect(field.format_implementation.next_luhn("100010-8")).to eq("100011-6")
  end

  it "checks for unicity" do
    expect(create_site_and_assign_default_values(nil).properties[field.es_code]).to eq("100000-9")
    expect do
      collection.sites.make(properties: {field.es_code => "100000-9"})
    end.to raise_exception(ActiveRecord::RecordInvalid, /The value already exists in the collection/)
  end

  it "updates site" do
    site = collection.sites.make
    site.properties[field.es_code] = site.properties[field.es_code]
    site.save!
  end

  it "gets new site properties" do
    props = collection.new_site_properties
    expect(props.length).to eq(1)
    expect(props[field.es_code]).to eq("100000-9")
  end

  it "do not search only in the first 50 when genetating values" do
    51.times do
      create_site_and_assign_default_values(nil)
    end
    expect do
      create_site_and_assign_default_values(nil)
    end.not_to raise_error
  end

  it "doesn't repeat id for deleted site" do
    collection.sites.make
    s1 = create_site_and_assign_default_values(nil)
    expect(s1.properties[field.es_code]).to eq("100000-9")

    s1.destroy

    expect(create_site_and_assign_default_values(nil).properties[field.es_code]).to eq("100001-7")
  end
end
