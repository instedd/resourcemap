require 'spec_helper'

describe BulkUpdate do
  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }

  it "imports with name, lat, lon and one numeric property" do
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

    BulkUpdate.import user, collection, csv_string
    BulkUpdate.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(1)
    layers[0].name.should eq(collection.name)

    fields = layers[0].fields.all
    fields.length.should eq(1)
    fields[0].name.should eq('The beds')
    fields[0].code.should eq('beds')
    fields[0].kind.should eq('numeric')

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({fields[0].es_code => 10})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({fields[0].es_code => 20})
  end

  it "imports with select one mapped to both code and label" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Visibility']
      csv << ['Foo', 'public']
      csv << ['Bar', 'private']
      csv << ['Baz', 'private']
      csv << ['', '']
    end

    specs = [
      {name: 'Name', kind: 'name'},
      {name: 'Visibility', kind: 'select_one', code: 'visibility', label: 'The visibility', selectKind: 'both'},
      ]

    BulkUpdate.import user, collection, csv_string
    BulkUpdate.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(1)
    layers[0].name.should eq(collection.name)

    fields = layers[0].fields.all
    fields.length.should eq(1)
    fields[0].name.should eq('The visibility')
    fields[0].code.should eq('visibility')
    fields[0].kind.should eq('select_one')
    fields[0].config.should eq('next_id' => 3, 'options' => [{'id' => 1, 'code' => 'public', 'label' => 'public'}, {'id' => 2, 'code' => 'private', 'label' => 'private'}])

    sites = collection.sites.all
    sites.length.should eq(3)

    sites[0].properties.should eq({fields[0].es_code => 1})
    sites[1].properties.should eq({fields[0].es_code => 2})
    sites[2].properties.should eq({fields[0].es_code => 2})
  end

  it "imports with two select ones mapped to code and label" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Visibility', 'Visibility Code']
      csv << ['Foo', 'public', '1']
      csv << ['Bar', 'private', '0']
      csv << ['Baz', 'private', '0']
      csv << ['', '', '']
    end

    specs = [
      {name: 'Name', kind: 'name'},
      {name: 'Visibility', kind: 'select_one', code: 'visibility', label: 'The visibility', selectKind: 'label'},
      {name: 'Visibility Code', kind: 'select_one', code: 'visibility', label: 'The visibility', selectKind: 'code'},
      ]

    BulkUpdate.import user, collection, csv_string
    BulkUpdate.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(1)
    layers[0].name.should eq(collection.name)

    fields = layers[0].fields.all
    fields.length.should eq(1)
    fields[0].name.should eq('The visibility')
    fields[0].code.should eq('visibility')
    fields[0].kind.should eq('select_one')
    fields[0].config.should eq('next_id' => 3, 'options' => [{'id' => 1, 'code' => '1', 'label' => 'public'}, {'id' => 2, 'code' => '0', 'label' => 'private'}])

    sites = collection.sites.all
    sites.length.should eq(3)

    sites[0].properties.should eq({fields[0].es_code => 1})
    sites[1].properties.should eq({fields[0].es_code => 2})
    sites[2].properties.should eq({fields[0].es_code => 2})
  end
end
