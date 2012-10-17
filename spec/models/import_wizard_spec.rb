require 'spec_helper'

describe ImportWizard do
  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }
  let!(:layer) { collection.layers.make }

  let!(:text) { layer.fields.make :code => 'text', :kind => 'text' }
  let!(:numeric) { layer.fields.make :code => 'numeric', :kind => 'numeric' }
  let!(:select_one) { layer.fields.make :code => 'select_one', :kind => 'select_one', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  let!(:select_many) { layer.fields.make :code => 'select_many', :kind => 'select_many', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  let!(:hierarchy) { layer.fields.make :code => 'hierarchy', :kind => 'hierarchy',  config: {hierarchy: [{"0"=>{"id"=>"60", "name"=>"papa"}, sub: [{"0"=> {"id"=>"100", "name"=>"uno"}, "1"=>{"id"=>"101", "name"=>"dos"}}.with_indifferent_access]}]}.with_indifferent_access}
  let!(:site) { layer.fields.make :code => 'site', :kind => 'site' }
  let!(:date) { layer.fields.make :code => 'date', :kind => 'date' }

  it "imports with name, lat, lon and one new numeric property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Lat', 'Lon', 'Beds']
      csv << ['Foo', '1.2', '3.4', '10']
      csv << ['Bar', '5.6', '7.8', '20']
      csv << ['', '', '', '']
    end

    specs = [
      {name: 'Name', usage: 'name'},
      {name: 'Lat', usage: 'lat'},
      {name: 'Lon', usage: 'lng'},
      {name: 'Beds', usage: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(2)
    layers[1].name.should eq('Import wizard')

    fields = layers[1].fields.all
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

  it "imports with name, lat, lon and one new numeric property and existing ID" do
    site1 = collection.sites.make name: 'Foo old', properties: {text.es_code => 'coco'}
    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}

    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Beds']
      csv << ["#{site1.id}", 'Foo', '1.2', '3.4', '10']
      csv << ["#{site2.id}", 'Bar', '5.6', '7.8', '20']
      csv << ['', '', '', '']
    end

    specs = [
      {name: 'resmap-id', usage: 'id'},
      {name: 'Name', usage: 'name'},
      {name: 'Lat', usage: 'lat'},
      {name: 'Lon', usage: 'lng'},
      {name: 'Beds', usage: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(2)
    layers[1].name.should eq('Import wizard')

    fields = layers[1].fields.all
    fields.length.should eq(1)
    fields[0].name.should eq('The beds')
    fields[0].code.should eq('beds')
    fields[0].kind.should eq('numeric')

    sites = collection.sites.all
    sites.length.should eq(2)

    site1.reload
    site1.name.should eq('Foo')
    site1.properties.should eq({fields[0].es_code => 10, text.es_code => 'coco'})

    site2.reload
    site2.name.should eq('Bar')
    site2.properties.should eq({fields[0].es_code => 20, text.es_code => 'lala'})
  end

  it "imports with name, lat, lon and one new numeric property and existing ID empty" do
    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Beds']
      csv << ["", 'Foo', '1.2', '3.4', '10']
      csv << ['', '', '', '']
    end

    specs = [
      {name: 'resmap-id', usage: 'id'},
      {name: 'Name', usage: 'name'},
      {name: 'Lat', usage: 'lat'},
      {name: 'Lon', usage: 'lng'},
      {name: 'Beds', usage: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(2)
    layers[1].name.should eq('Import wizard')

    fields = layers[1].fields.all
    fields.length.should eq(1)
    fields[0].name.should eq('The beds')
    fields[0].code.should eq('beds')
    fields[0].kind.should eq('numeric')

    sites = collection.sites.all
    sites.length.should eq(1)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({fields[0].es_code => 10})
  end

  it "imports with new select one mapped to both code and label" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Visibility']
      csv << ['Foo', 'public']
      csv << ['Bar', 'private']
      csv << ['Baz', 'private']
      csv << ['', '']
    end

    specs = [
      {name: 'Name', usage: 'name'},
      {name: 'Visibility', usage: 'new_field', kind: 'select_one', code: 'visibility', label: 'The visibility', selectKind: 'both'},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(2)
    layers[1].name.should eq('Import wizard')

    fields = layers[1].fields.all
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

  it "imports with two new select ones mapped to code and label" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Visibility', 'Visibility Code']
      csv << ['Foo', 'public', '1']
      csv << ['Bar', 'private', '0']
      csv << ['Baz', 'private', '0']
      csv << ['', '', '']
    end

    specs = [
      {name: 'Name', usage: 'name'},
      {name: 'Visibility', usage: 'new_field', kind: 'select_one', code: 'visibility', label: 'The visibility', selectKind: 'label'},
      {name: 'Visibility Code', usage: 'new_field', kind: 'select_one', code: 'visibility', label: 'The visibility', selectKind: 'code'},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(2)
    layers[1].name.should eq('Import wizard')

    fields = layers[1].fields.all
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

  it "imports with name and existing text property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', 'hi']
      csv << ['Bar', 'bye']
      csv << ['', '', '', '']
    end

    specs = [
      {name: 'Name', usage: 'name'},
      {name: 'Column', usage: 'existing_field', field_id: text.id},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({text.es_code => 'hi'})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({text.es_code => 'bye'})
  end

  it "imports with name and existing numeric property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', '10']
      csv << ['Bar', '20']
      csv << ['', '', '', '']
    end

    specs = [
      {name: 'Name', usage: 'name'},
      {name: 'Column', usage: 'existing_field', field_id: numeric.id},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({numeric.es_code => 10})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({numeric.es_code => 20})
  end

  it "imports with name and existing select_one property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', 'one']
      csv << ['Bar', 'two']
      csv << ['', '', '', '']
    end

    specs = [
      {name: 'Name', usage: 'name'},
      {name: 'Column', usage: 'existing_field', field_id: select_one.id},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({select_one.es_code => 1})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({select_one.es_code => 2})
  end

  it "imports with name and existing select_one property but creates new option" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', 'three']
      csv << ['Bar', 'four']
      csv << ['', '', '', '']
    end

    specs = [
      {name: 'Name', usage: 'name'},
      {name: 'Column', usage: 'existing_field', field_id: select_one.id},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])

    select_one.reload
    select_one.config['options'].length.should eq(4)

    select_one.config['options'][2]['id'].should eq(3)
    select_one.config['options'][2]['code'].should eq('three')
    select_one.config['options'][2]['label'].should eq('three')

    select_one.config['options'][3]['id'].should eq(4)
    select_one.config['options'][3]['code'].should eq('four')
    select_one.config['options'][3]['label'].should eq('four')

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({select_one.es_code => 3})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({select_one.es_code => 4})
  end

  it "imports with name and existing select_many property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', 'one']
      csv << ['Bar', 'one, two']
      csv << ['', '', '', '']
    end

    specs = [
      {name: 'Name', usage: 'name'},
      {name: 'Column', usage: 'existing_field', field_id: select_many.id},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({select_many.es_code => [1]})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({select_many.es_code => [1, 2]})
  end

  it "imports with name and existing select_many property creates new options" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', 'one, three']
      csv << ['Bar', 'two, four']
      csv << ['', '', '', '']
    end

    specs = [
      {name: 'Name', usage: 'name'},
      {name: 'Column', usage: 'existing_field', field_id: select_many.id},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])

    select_many.reload
    select_many.config['options'].length.should eq(4)

    select_many.config['options'][2]['id'].should eq(3)
    select_many.config['options'][2]['code'].should eq('three')
    select_many.config['options'][2]['label'].should eq('three')

    select_many.config['options'][3]['id'].should eq(4)
    select_many.config['options'][3]['code'].should eq('four')
    select_many.config['options'][3]['label'].should eq('four')

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Foo')
    sites[0].properties.should eq({select_many.es_code => [1, 3]})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({select_many.es_code => [2, 4]})
  end

  it "should update hierarchy fields in bulk update" do
     csv_string = CSV.generate do |csv|
        csv << ['Name', 'Column']
        csv << ['Foo', 101]
        csv << ['Bar', 100]
      end

      specs = [
        {name: 'Name', usage: 'name'},
        {name: 'Column', usage: 'existing_field', field_id: hierarchy.id},
        ]

      ImportWizard.import user, collection, csv_string
      ImportWizard.execute user, collection, specs

      collection.layers.all.should eq([layer])
      sites = collection.sites.all

      sites[0].name.should eq('Foo')
      sites[0].properties.should eq({hierarchy.es_code => "101"})

      sites[1].name.should eq('Bar')
      sites[1].properties.should eq({hierarchy.es_code => "100"})

  end

  it "imports with name and existing date property" do
     csv_string = CSV.generate do |csv|
       csv << ['Name', 'Column']
       csv << ['Foo', '12/24/2012']
       csv << ['Bar', '10/23/2033']
       csv << ['', '', '', '']
     end

     specs = [
       {name: 'Name', usage: 'name'},
       {name: 'Column', usage: 'existing_field', field_id: date.id},
       ]

     ImportWizard.import user, collection, csv_string
     ImportWizard.execute user, collection, specs

     collection.layers.all.should eq([layer])

     sites = collection.sites.all
     sites.length.should eq(2)

     sites[0].name.should eq('Foo')
     sites[0].properties.should eq({date.es_code => "2012-12-24T00:00:00Z"})

     sites[1].name.should eq('Bar')
     sites[1].properties.should eq({date.es_code => "2033-10-23T00:00:00Z"})
   end

  it "imports with name and existing site property" do

    collection.sites.make :name => 'Site1', :id => '123'

    csv_string = CSV.generate do |csv|
     csv << ['Name', 'Column']
     csv << ['Foo', '123']
     csv << ['', '', '', '']
    end

    specs = [
     {name: 'Name', usage: 'name'},
     {name: 'Column', usage: 'existing_field', field_id: site.id},
     ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    collection.layers.all.should eq([layer])

    sites = collection.sites.all
    sites.length.should eq(2)

    sites[0].name.should eq('Site1')

    sites[1].name.should eq('Foo')
    sites[1].properties.should eq({site.es_code => "123"})
  end

  it "should update all property values" do
    site1 = collection.sites.make name: 'Foo old', id: 1234, properties: {
      text.es_code => 'coco',
      numeric.es_code => 10,
      select_one.es_code => 1,
      select_many.es_code => [1, 2],
      hierarchy.es_code => 60,
      site.es_code => 1234,
      date.es_code => "2012-10-24T03:00:00.000Z"
    }

    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235


    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Text', 'Numeric', 'Select One', 'Select Many', 'Hierarchy', 'Site', 'Date']
      csv << ["#{site1.id}", 'Foo new', '1.2', '3.4', 'new val', 11, 'two', 'two', 'uno',  1235, '12/26/1988']
    end

    specs = [
      {name: 'resmap-id', usage: 'id'},
      {name: 'Name', usage: 'name'},
      {name: 'Text', usage: 'existing_field', field_id: text.id},
      {name: 'Numeric', usage: 'existing_field', field_id: numeric.id},
      {name: 'Select One', usage: 'existing_field', field_id: select_one.id},
      {name: 'Select Many', usage: 'existing_field', field_id: select_many.id},
      {name: 'Hierarchy', usage: 'existing_field', field_id: hierarchy.id},
      {name: 'Site', usage: 'existing_field', field_id: site.id},
      {name: 'Date', usage: 'existing_field', field_id: date.id},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(1)
    layers[0].name.should eq(layer.name)

    fields = layers[0].fields.all
    fields.length.should eq(7)

    sites = collection.sites.all
    sites.length.should eq(2)

    site1.reload
    site1.name.should eq('Foo new')
    site1.properties.should eq({
      text.es_code => 'new val',
      numeric.es_code => 11,
      select_one.es_code => 2,
      select_many.es_code => [2],
      hierarchy.es_code => 'uno',
      site.es_code => '1235',
      date.es_code => "1988-12-26T00:00:00Z"
    })

    site2.reload
    site2.name.should eq('Bar old')
    site2.properties.should eq({text.es_code => 'lala'})
  end

end
