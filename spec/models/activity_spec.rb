require 'spec_helper'

describe Activity do
  let!(:user) { User.make }

  it "creates one when collection is created" do
    collection = Collection.make_unsaved
    user.create_collection collection

    activities = Activity.all
    activities.length.should eq(1)

    activities[0].kind.should eq('collection_created')
    activities[0].collection_id.should eq(collection.id)
    activities[0].user_id.should eq(user.id)
  end

  it "creates one when layer is created" do
    collection = user.create_collection Collection.make_unsaved
    Activity.delete_all

    layer = collection.layers.make_unsaved
    layer.user = user
    layer.save!

    activities = Activity.all
    activities.length.should eq(1)

    activities[0].kind.should eq('layer_created')
    activities[0].collection_id.should eq(collection.id)
    activities[0].layer_id.should eq(layer.id)
    activities[0].user_id.should eq(user.id)
  end
end
