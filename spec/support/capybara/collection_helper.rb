module Capybara::CollectionHelper

  def create_collection_for(user)
  	collection = Collection.make(:name => 'Central Hospital')
    @user.create_collection(collection)
    @user.memberships.first.should be_admin
  end

  def create_site_for(collection)
  	site = Site.make(:collection => collection)
  	#site = Site.make(:name => 'Health Center')
    #@user.create_site(site)
    #@user.memberships.first.should be_admin
  end

  def create_layer_for
  	Layer.make(collection_id: 1, :name => 'This Layer belongs to the Central Hospital')
  end
end