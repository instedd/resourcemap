require 'spec_helper'

describe FieldHistory do
  auth_scope(:user) { User.make }
  let(:collection) { user.create_collection Collection.make_unsaved }

  it "reindexes collection after destroy field" do
    Timecop.freeze(Time.now) do
      layer = collection.layers.make
      numeric = layer.numeric_fields.make code: 'numeric'
      site = collection.sites.make properties: {numeric.es_code => 1}

      snapshot = collection.snapshots.make date: Time.now
      numeric.destroy

      snapshot.collection.field_histories.each do |field_history|
        field_history.allow_decimals?
      end
    end
  end
end
