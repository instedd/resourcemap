require 'spec_helper'
require 'serializers/spec_helper'

describe Api::CollectionSerializer do
  let(:collection) { Collection.make }
  let(:serializer) { Api::CollectionSerializer.new collection }

	it "preserves backwards compatibility" do
    expect_fields_rendered_by serializer do
      [
        :anonymous_location_permission,
        :anonymous_name_permission, 
        :created_at, 
        :description, 
        :icon, 
        :id, 
        :lat, 
        :lng,
        :max_lat,
        :max_lng,
        :min_lat,
        :min_lng,
        :name,
        :updated_at
      ]
    end
  end

  it "includes the site count" do
    sites = [collection.sites.make, collection.sites.make]

    expect_fields_rendered_by serializer do
      { :count => 2 }
    end
  end
end