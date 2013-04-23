module Capybara::CollectionHelper

  def create_collection_for(user)
  	collection = Collection.make(:name => 'Central Hospital')
    @user.create_collection(collection)
    @user.memberships.first.should be_admin
  end

  def create_site_for(collection)
  	site = Site.make(:collection => collection)
  end

  def create_layer_for
  	Layer.make(collection_id: 1, :name => 'Central Hospital Layer 1')
  end

  def create_field_for
  	field = Field::TextField.make(:name => 'Central Hospital Layer 1 Field', collection_id: 1, layer_id: 1)
  end
end