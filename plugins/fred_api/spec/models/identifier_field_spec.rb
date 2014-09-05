require 'spec_helper'

describe "Identifier field" do
  let(:collection) { Collection.make }
  let(:layer) { collection.layers.make }
  let!(:field) { layer.identifier_fields.make config: {"context" => "MOH", "agency" => "DHIS", "format" => "Normal"} }

  context "validation" do

    it "doesn't fail if blank" do
      field.apply_format_and_validate("", nil, collection)
    end

    it "checks for unicity" do
      site = collection.sites.make properties: {field.es_code => "1"}

      lambda do
        collection.sites.make properties: {field.es_code => "1"}
      end.should raise_exception(ActiveRecord::RecordInvalid, /The value already exists in the collection/)
    end
  end
end
