module Capybara::CollectionHelper

  def create_collection_for(user)
    collection = user.collections.make name: 'Central Hospital'
    user.memberships.make collection: collection, admin: true
    collection
  end

  def create_site_for(collection, site_name="Health Center")
    collection.sites.make(:name => site_name, :lng => 14.3574, :lat => 26.7574)
  end

  def create_layer_for(collection)
    collection.layers.make(:name => 'Central Hospital Layer 1')
  end

  def create_field_for (layer)
  	layer.text_fields.make(:name => 'Central Hospital Layer 1 Field', :code => 'CHL1F')
  end

  def first_collection_path
    '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button'
  end

end
