module Capybara::CollectionHelper

  def create_collection_for(user)
  	collection = Collection.make(:name => 'Central Hospital')
    @user.create_collection(collection).should eq(collection)
    @user.collections.should eq([collection])
    @user.memberships.first.should be_admin
  end
end