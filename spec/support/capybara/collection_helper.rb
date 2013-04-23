module Capybara::CollectionHelper

  def create_collection_for (user)
    collection = user.collections.make name: 'Central Hospital'
    user.memberships.make collection: collection
    collection
  end

  def create_site_for(collection)
    collection.sites.make(:name => 'Health Center', :lng => 14.3574, :lat => 26.7574)
  end

  def create_layer_for
  	Layer.make(collection_id: 1, :name => 'Central Hospital Layer 1')
  end

  def create_field_for
  	Field::TextField.make(:name => 'Central Hospital Layer 1 Field', collection_id: 1, layer_id: 1)
  end

end