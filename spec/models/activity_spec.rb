require 'spec_helper'

describe Activity do
  let!(:user) { User.make }

  it "creates one when collection is created" do
    collection = Collection.make_unsaved
    user.create_collection collection

    assert_activity 'collection_created',
      collection_id: collection.id,
      user_id: user.id,
      data: {name: collection.name},
      description: "Collection was created with name: #{collection.name}"
  end

  it "creates one when layer is created" do
    collection = user.create_collection Collection.make_unsaved
    Activity.delete_all

    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

    assert_activity 'layer_created',
      collection_id: collection.id,
      layer_id: layer.id,
      user_id: user.id,
      data: {fields: [{id: layer.fields.first.id, kind: 'text', code: 'foo', name: 'Foo'}]},
      description: 'Layer was created with fields: Foo (foo)'
  end

  it "creates one after running the import wizard" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Lat', 'Lon', 'Beds']
      csv << ['Foo', '1.2', '3.4', '10']
      csv << ['Bar', '5.6', '7.8', '20']
      csv << ['', '', '', '']
    end

    specs = [
      {name: 'Name', kind: 'name'},
      {name: 'Lat', kind: 'lat'},
      {name: 'Lon', kind: 'lng'},
      {name: 'Beds', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    collection = user.create_collection Collection.make_unsaved
    Activity.delete_all

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    assert_activity 'collection_imported',
      collection_id: collection.id,
      user_id: user.id,
      layer_id: collection.layers.first.id,
      data: {groups: 0, sites: 2},
      description: 'Import wizard: 0 groups and 2 sites were imported'
  end

  def assert_activity(kind, options = {})
    activities = Activity.all
    activities.length.should eq(1)

    options.each do |key, value|
      activities[0].send(key).should eq(value)
    end
  end
end
