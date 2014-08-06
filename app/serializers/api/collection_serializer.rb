class Api::CollectionSerializer < ActiveModel::Serializer
  attributes :anonymous_location_permission, :anonymous_name_permission, :created_at, :description, :icon, :id, :lat, :lng, :max_lat, :max_lng, :min_lat, :min_lng, :name, :updated_at, :count

  def count
  	object.sites.count
  end
end
