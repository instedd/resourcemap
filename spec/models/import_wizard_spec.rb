# encoding: UTF-8
require 'spec_helper'

describe ImportWizard, :type => :model do
  let!(:user) { User.make }

  let!(:collection) { user.create_collection Collection.make_unsaved }
  let!(:user2) { collection.users.make :email => 'user2@email.com'}
  let!(:membership) { collection.memberships.create! :user_id => user2.id }

  let!(:layer) { collection.layers.make }

  let!(:text) { layer.text_fields.make :code => 'text' }
  let!(:numeric) { layer.numeric_fields.make :code => 'numeric'}
  let!(:yes_no) { layer.yes_no_fields.make :code => 'yes_no' }
  let!(:select_one) { layer.select_one_fields.make :code => 'select_one', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  let!(:select_many) { layer.select_many_fields.make :code => 'select_many', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
  let!(:hierarchy) { layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access }
  let!(:site) { layer.site_fields.make :code => 'site'}
  let!(:date) { layer.date_fields.make :code => 'date' }
  let!(:director) { layer.user_fields.make :code => 'user' }

  it "imports with name, lat, lon and one new numeric property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Lat', 'Lon', 'Beds']
      csv << ['Foo', '1.2', '3.4', '10']
      csv << ['Bar', '5.6', '7.8', '20']
      csv << ['', '', '', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'},
      {header: 'Beds', use_as: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(2)
    expect(layers[1].name).to eq('Import wizard')

    fields = layers[1].fields
    expect(fields.length).to eq(1)
    expect(fields[0].name).to eq('The beds')
    expect(fields[0].code).to eq('beds')
    expect(fields[0].kind).to eq('numeric')

    sites = collection.sites.reload
    expect(sites.length).to eq(2)

    expect(sites[0].name).to eq('Foo')
    expect(sites[0].properties).to eq({fields[0].es_code => 10})

    expect(sites[1].name).to eq('Bar')
    expect(sites[1].properties).to eq({fields[0].es_code => 20})
  end

  it "imports with a new numeric field that allows decimal numbers" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Lat', 'Lon', 'Beds']
      csv << ['Foo', '1.2', '3.4', '10.151']
      csv << ['Bar', '5.6', '7.8', '20.223']
      csv << ['', '', '', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'},
      {header: 'Beds', use_as: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds', config: {"allows_decimals"=>true} },
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string
    ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(2)
    expect(layers[1].name).to eq('Import wizard')

    fields = layers[1].fields
    expect(fields.length).to eq(1)
    expect(fields[0].name).to eq('The beds')
    expect(fields[0].code).to eq('beds')
    expect(fields[0].kind).to eq('numeric')
    expect(fields[0].allow_decimals?).to be_truthy

    sites = collection.sites.reload
    expect(sites.length).to eq(2)

    expect(sites[0].name).to eq('Foo')
    expect(sites[0].properties).to eq({fields[0].es_code => 10.151})

    expect(sites[1].name).to eq('Bar')
    expect(sites[1].properties).to eq({fields[0].es_code => 20.223})
  end


  it "import should calculate collection bounds from sites" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Lat', 'Lon']
      csv << ['Foo', '30.0', '20.0']
      csv << ['Bar', '40.0', '30.0']
      csv << ['FooBar', '45.0', '40.0']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'}
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    collection.reload
    expect(collection.min_lat.to_f).to eq(30.0)
    expect(collection.max_lat.to_f).to eq(45.0)
    expect(collection.min_lng.to_f).to eq(20.0)
    expect(collection.max_lng.to_f).to eq(40.0)
    expect(collection.lat.to_f).to eq(37.5)
    expect(collection.lng.to_f).to eq(30.0)
  end

  it "imports with name, lat, lon and one new numeric property and existing ID" do
    site1 = collection.sites.make name: 'Foo old', properties: {text.es_code => 'coco'}
    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}

    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Beds']
      csv << ["#{site1.id}", 'Foo', '1.2', '3.4', '10']
      csv << ["#{site2.id}", 'Bar', '5.6', '7.8', '20']
      csv << ['', '', '', '', '']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id'},
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'},
      {header: 'Beds', use_as: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(2)
    expect(layers[1].name).to eq('Import wizard')

    fields = layers[1].fields
    expect(fields.length).to eq(1)
    expect(fields[0].name).to eq('The beds')
    expect(fields[0].code).to eq('beds')
    expect(fields[0].kind).to eq('numeric')

    sites = collection.sites.reload
    expect(sites.length).to eq(2)

    site1.reload
    expect(site1.name).to eq('Foo')
    expect(site1.properties).to eq({fields[0].es_code => 10, text.es_code => 'coco'})

    site2.reload
    expect(site2.name).to eq('Bar')
    expect(site2.properties).to eq({fields[0].es_code => 20, text.es_code => 'lala'})
  end

  it "imports with name, lat, lon and one new numeric property and existing ID empty" do
    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Beds']
      csv << ["", 'Foo', '1.2', '3.4', '10']
      csv << ['', '', '', '', '']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id'},
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'},
      {header: 'Beds', use_as: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(2)
    expect(layers[1].name).to eq('Import wizard')

    fields = layers[1].fields
    expect(fields.length).to eq(1)
    expect(fields[0].name).to eq('The beds')
    expect(fields[0].code).to eq('beds')
    expect(fields[0].kind).to eq('numeric')

    sites = collection.sites.reload
    expect(sites.length).to eq(1)

    expect(sites[0].name).to eq('Foo')
    expect(sites[0].properties).to eq({fields[0].es_code => 10})
  end

  it "New sites are created when importing and using rows with no value(nil) or blank space in resmap-id column" do
    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Beds','Soap']
      csv << ["", 'Foo', '1.2', '3.4', '1','1']
      csv << [nil, 'Bar', '10', '40', '10','10']
      csv << [" ", 'Fin de semana', '10', '40', '20','20']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id'},
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'},
      {header: 'Beds', use_as: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      {header: 'Soap', use_as: 'new_field', kind: 'numeric', code: 'soap', label: 'sp'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(2)
    expect(layers[1].name).to eq('Import wizard')

    fields = layers[1].fields
    expect(fields.length).to eq(2)
    expect(fields[0].name).to eq('The beds')
    expect(fields[0].code).to eq('beds')
    expect(fields[0].kind).to eq('numeric')

    sites = collection.sites.reload
    expect(sites.length).to eq(3)

    expect(sites[0].name).to eq('Foo')
    expect(sites[0].properties).to eq({fields[0].es_code => 1,fields[1].es_code => 1})
    expect(sites[1].name).to eq('Bar')
    expect(sites[1].properties).to eq({fields[0].es_code => 10,fields[1].es_code => 10})
    expect(sites[2].name).to eq('Fin de semana')
    expect(sites[2].properties).to eq({fields[0].es_code => 20,fields[1].es_code => 20})
  end

  it "imports by downloading and uploading an empty collection with numeric field" do
    sample_csv = collection.sample_csv user
    ImportWizard.import user, collection, 'sample.csv', sample_csv
    ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection
    processed_sites = (ImportWizard.validate_sites_with_columns user, collection, column_spec)
    expect(processed_sites[:errors][:data_errors].count).to eq(0)
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
      {header: 'Name', use_as: 'name'},
      {header: 'Visibility', use_as: 'new_field', kind: 'select_one', code: 'visibility', label: 'The visibility', selectKind: 'both'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(2)
    expect(layers[1].name).to eq('Import wizard')

    fields = layers[1].fields
    expect(fields.length).to eq(1)
    expect(fields[0].name).to eq('The visibility')
    expect(fields[0].code).to eq('visibility')
    expect(fields[0].kind).to eq('select_one')
    expect(fields[0].config).to eq('next_id' => 3, 'options' => [{'id' => 1, 'code' => 'public', 'label' => 'public'}, {'id' => 2, 'code' => 'private', 'label' => 'private'}])

    sites = collection.sites.reload
    expect(sites.length).to eq(3)

    expect(sites[0].properties).to eq({fields[0].es_code => 1})
    expect(sites[1].properties).to eq({fields[0].es_code => 2})
    expect(sites[2].properties).to eq({fields[0].es_code => 2})
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
      {header: 'Name', use_as: 'name'},
      {header: 'Visibility', use_as: 'new_field', kind: 'select_one', code: 'visibility', label: 'The visibility', selectKind: 'label'},
      {header: 'Visibility Code', use_as: 'new_field', kind: 'select_one', code: 'visibility', label: 'The visibility', selectKind: 'code'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(2)
    expect(layers[1].name).to eq('Import wizard')

    fields = layers[1].fields
    expect(fields.length).to eq(1)
    expect(fields[0].name).to eq('The visibility')
    expect(fields[0].code).to eq('visibility')
    expect(fields[0].kind).to eq('select_one')
    expect(fields[0].config).to eq('next_id' => 3, 'options' => [{'id' => 1, 'code' => '1', 'label' => 'public'}, {'id' => 2, 'code' => '0', 'label' => 'private'}])

    sites = collection.sites.reload
    expect(sites.length).to eq(3)

    expect(sites[0].properties).to eq({fields[0].es_code => 1})
    expect(sites[1].properties).to eq({fields[0].es_code => 2})
    expect(sites[2].properties).to eq({fields[0].es_code => 2})
  end

  it "imports with name and existing text property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', 'hi']
      csv << ['Bar', 'bye']
      csv << ['', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Column', use_as: 'existing_field', field_id: text.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    expect(collection.layers).to eq([layer])

    sites = collection.sites.reload
    expect(sites.length).to eq(2)

    expect(sites[0].name).to eq('Foo')
    expect(sites[0].properties).to eq({text.es_code => 'hi'})

    expect(sites[1].name).to eq('Bar')
    expect(sites[1].properties).to eq({text.es_code => 'bye'})
  end

  it "imports with name and existing numeric property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', '10']
      csv << ['Bar', '20']
      csv << ['', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Column', use_as: 'existing_field', field_id: numeric.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    expect(collection.layers).to eq([layer])

    sites = collection.sites.reload
    expect(sites.length).to eq(2)

    expect(sites[0].name).to eq('Foo')
    expect(sites[0].properties).to eq({numeric.es_code => 10})

    expect(sites[1].name).to eq('Bar')
    expect(sites[1].properties).to eq({numeric.es_code => 20})
  end

  it "imports with name and existing select_one property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', 'one']
      csv << ['Bar', 'two']
      csv << ['', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Column', use_as: 'existing_field', field_id: select_one.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    expect(collection.layers).to eq([layer])

    sites = collection.sites.reload
    expect(sites.length).to eq(2)

    expect(sites[0].name).to eq('Foo')
    expect(sites[0].properties).to eq({select_one.es_code => 1})

    expect(sites[1].name).to eq('Bar')
    expect(sites[1].properties).to eq({select_one.es_code => 2})
  end

  it "imports with name and existing select_many property" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', 'one']
      csv << ['Bar', 'one, two']
      csv << ['', '']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Column', use_as: 'existing_field', field_id: select_many.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    expect(collection.layers).to eq([layer])

    sites = collection.sites.reload
    expect(sites.length).to eq(2)

    expect(sites[0].name).to eq('Foo')
    expect(sites[0].properties).to eq({select_many.es_code => [1]})

    expect(sites[1].name).to eq('Bar')
    expect(sites[1].properties).to eq({select_many.es_code => [1, 2]})
  end

  it "should also update hierarchy fields in bulk update using name" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', 'Son']
      csv << ['Bar', 'Bro']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Column', use_as: 'existing_field', field_id: hierarchy.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    expect(collection.layers).to eq([layer])
    sites = collection.sites.reload

    expect(sites[0].name).to eq('Foo')
    expect(sites[0].properties).to eq({hierarchy.es_code => "100"})

    expect(sites[1].name).to eq('Bar')
    expect(sites[1].properties).to eq({hierarchy.es_code => "101"})
  end

  it "should update hierarchy fields in bulk update using id" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Column']
      csv << ['Foo', '100']
      csv << ['Bar', '101']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Column', use_as: 'existing_field', field_id: hierarchy.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    expect(collection.layers).to eq([layer])
    sites = collection.sites.reload

    expect(sites[0].name).to eq('Foo')
    expect(sites[0].properties).to eq({hierarchy.es_code => "100"})

    expect(sites[1].name).to eq('Bar')
    expect(sites[1].properties).to eq({hierarchy.es_code => "101"})
  end

  it "imports with name and existing date property" do
     csv_string = CSV.generate do |csv|
       csv << ['Name', 'Column']
       csv << ['Foo', '12/24/2012']
       csv << ['Bar', '10/23/2033']
       csv << ['', '']
     end

     specs = [
       {header: 'Name', use_as: 'name'},
       {header: 'Column', use_as: 'existing_field', field_id: date.id},
       ]

     ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
     ImportWizard.execute user, collection, specs

     expect(collection.layers).to eq([layer])

     sites = collection.sites.reload
     expect(sites.length).to eq(2)

     expect(sites[0].name).to eq('Foo')
     expect(sites[0].properties).to eq({date.es_code => "2012-12-24T00:00:00Z"})

     expect(sites[1].name).to eq('Bar')
     expect(sites[1].properties).to eq({date.es_code => "2033-10-23T00:00:00Z"})
  end

  it "imports with name and existing site property" do

    collection.sites.make :name => 'Site1', :id => '123'

    csv_string = CSV.generate do |csv|
     csv << ['Name', 'Column']
     csv << ['Foo', '123']
     csv << ['', '']
    end

    specs = [
     {header: 'Name', use_as: 'name'},
     {header: 'Column', use_as: 'existing_field', field_id: site.id},
     ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    expect(collection.layers).to eq([layer])

    sites = collection.sites.reload
    expect(sites.length).to eq(2)

    expect(sites[0].name).to eq('Site1')

    expect(sites[1].name).to eq('Foo')
    expect(sites[1].properties).to eq({site.es_code => "123"})
  end

  it "should update all property values" do
    site1 = collection.sites.make name: 'Foo old', id: 1234, properties: {
      text.es_code => 'coco',
      numeric.es_code => 10,
      yes_no.es_code => true,
      select_one.es_code => 1,
      select_many.es_code => [1, 2],
      hierarchy.es_code => 60,
      date.es_code => "2012-10-24T00:00:00Z",
      director.es_code => user.email
    }
    site1.properties[site.es_code] = site1.id

    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235


    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Text', 'Numeric', 'Yes no', 'Select One', 'Select Many', 'Hierarchy', 'Site', 'Date', 'User']
      csv << ["#{site1.id}", 'Foo new', '1.2', '3.4', 'new val', 11, 'no', 'two', 'two, one', 'Dad',  1235, '12/26/1988', 'user2@email.com']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id'},
      {header: 'Name', use_as: 'name'},
      {header: 'Text', use_as: 'existing_field', field_id: text.id},
      {header: 'Numeric', use_as: 'existing_field', field_id: numeric.id},
      {header: 'Yes no', use_as: 'existing_field', field_id: yes_no.id},
      {header: 'Select One', use_as: 'existing_field', field_id: select_one.id},
      {header: 'Select Many', use_as: 'existing_field', field_id: select_many.id},
      {header: 'Hierarchy', use_as: 'existing_field', field_id: hierarchy.id},
      {header: 'Site', use_as: 'existing_field', field_id: site.id},
      {header: 'Date', use_as: 'existing_field', field_id: date.id},
      {header: 'User', use_as: 'existing_field', field_id: director.id},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(1)
    expect(layers[0].name).to eq(layer.name)

    fields = layers[0].fields
    expect(fields.length).to eq(9)

    sites = collection.sites.reload
    expect(sites.length).to eq(2)

    site1.reload
    expect(site1.name).to eq('Foo new')
    expect(site1.properties).to eq({
      text.es_code => 'new val',
      numeric.es_code => 11,
      yes_no.es_code => false,
      select_one.es_code => 2,
      select_many.es_code => [2, 1],
      hierarchy.es_code => '60',
      site.es_code => '1235',
      date.es_code => "1988-12-26T00:00:00Z",
      director.es_code => 'user2@email.com'
    })

    site2.reload
    expect(site2.name).to eq('Bar old')
    expect(site2.properties).to eq({text.es_code => 'lala'})
  end

  it "should delete all property values with empty strings" do
    site1 = collection.sites.make name: 'Foo old', id: 1234, properties: {
      text.es_code => 'coco',
      numeric.es_code => 10,
      select_one.es_code => 1,
      select_many.es_code => [1, 2],
      hierarchy.es_code => 60,
      date.es_code => "2012-10-24T00:00:00Z",
      director.es_code => user.email
    }
    site1.properties[site.es_code] = site1.id


    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235

    csv_string = CSV.generate do |csv|
     csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Text', 'Numeric', 'Select One', 'Select Many', 'Hierarchy', 'Site', 'Date', 'User']
     csv << ["#{site1.id}", 'Foo old', '1.2', '3.4', '', '', '', '', '',  '', '', '']
    end

    specs = [
     {header: 'resmap-id', use_as: 'id'},
     {header: 'Name', use_as: 'name'},
     {header: 'Text', use_as: 'existing_field', field_id: text.id},
     {header: 'Numeric', use_as: 'existing_field', field_id: numeric.id},
     {header: 'Select One', use_as: 'existing_field', field_id: select_one.id},
     {header: 'Select Many', use_as: 'existing_field', field_id: select_many.id},
     {header: 'Hierarchy', use_as: 'existing_field', field_id: hierarchy.id},
     {header: 'Site', use_as: 'existing_field', field_id: site.id},
     {header: 'Date', use_as: 'existing_field', field_id: date.id},
     {header: 'User', use_as: 'existing_field', field_id: director.id},
     ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(1)
    expect(layers[0].name).to eq(layer.name)

    fields = layers[0].fields
    expect(fields.length).to eq(9)

    sites = collection.sites.reload
    expect(sites.length).to eq(2)

    site1.reload
    expect(site1.name).to eq('Foo old')
    expect(site1.properties).to eq({})

    site2.reload
    expect(site2.name).to eq('Bar old')
    expect(site2.properties).to eq({text.es_code => 'lala'})
  end


  it "should delete all property values with nil values" do
    site1 = collection.sites.make name: 'Foo old', id: 1234, properties: {
      text.es_code => 'coco',
      numeric.es_code => 10,
      select_one.es_code => 1,
      select_many.es_code => [1, 2],
      hierarchy.es_code => 60,
      date.es_code => "2012-10-24T00:00:00Z",
      director.es_code => user.email
    }
    site1.properties[site.es_code] = site1.id


    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235

    csv_string = CSV.generate do |csv|
     csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Text', 'Numeric', 'Select One', 'Select Many', 'Hierarchy', 'Site', 'Date', 'User']
     csv << ["#{site1.id}", 'Foo old', '1.2', '3.4', nil, nil, nil, nil, nil,  nil, nil, nil]
    end

    specs = [
     {header: 'resmap-id', use_as: 'id'},
     {header: 'Name', use_as: 'name'},
     {header: 'Text', use_as: 'existing_field', field_id: text.id},
     {header: 'Numeric', use_as: 'existing_field', field_id: numeric.id},
     {header: 'Select One', use_as: 'existing_field', field_id: select_one.id},
     {header: 'Select Many', use_as: 'existing_field', field_id: select_many.id},
     {header: 'Hierarchy', use_as: 'existing_field', field_id: hierarchy.id},
     {header: 'Site', use_as: 'existing_field', field_id: site.id},
     {header: 'Date', use_as: 'existing_field', field_id: date.id},
     {header: 'User', use_as: 'existing_field', field_id: director.id},
     ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(1)
    expect(layers[0].name).to eq(layer.name)

    fields = layers[0].fields
    expect(fields.length).to eq(9)

    sites = collection.sites.reload
    expect(sites.length).to eq(2)

    site1.reload
    expect(site1.name).to eq('Foo old')
    expect(site1.properties).to eq({})

    site2.reload
    expect(site2.name).to eq('Bar old')
    expect(site2.properties).to eq({text.es_code => 'lala'})
  end

  it "should not create a new hierarchy field in import wizard" do
    csv_string = CSV.generate do |csv|
      csv << ['Hierarchy']
      csv << ['Dad']
    end

    specs = [
      {header: 'Hierarchy', use_as: 'new_field', kind: 'hierarchy', code: 'new_hierarchy'},
    ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    expect { ImportWizard.execute(user, collection, specs) }.to raise_error

  end

  it "should create new fields with all property values" do
    site1 = collection.sites.make name: 'Foo old', id: 1234, properties: {}

    site2 = collection.sites.make name: 'Bar old', properties: {}, id: 1235

    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Text', 'Numeric', 'Yes no', 'Select One', 'Select Many', 'Site', 'Date', 'User', 'Email', 'Phone']
      csv << ["#{site1.id}", 'Foo new', '1.2', '3.4', 'new val', 11, 'no', 'two', 'two, one',  1235, '12/26/1988', 'user2@email.com', 'new@email.com', '1456']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id'},
      {header: 'Name', use_as: 'name'},
      {header: 'Text', use_as: 'new_field', kind: 'text', code: 'new_text'},
      {header: 'Numeric', use_as: 'new_field', kind: 'numeric', code: 'new_numeric'},
      {header: 'Yes no', use_as: 'new_field', kind: 'yes_no', code: 'new_yes_no'},
      {header: 'Select One', use_as: 'new_field', kind: 'select_one', code: 'new_select_one', label: 'New Select One', selectKind: 'both'},
      {header: 'Select Many', use_as: 'new_field', kind: 'select_many', code: 'new_select_many', label: 'New Select Many', selectKind: 'both'},
      {header: 'Site', use_as: 'new_field', kind: 'site', code: 'new_site'},
      {header: 'Date', use_as: 'new_field', kind: 'date', code: 'new_date'},
      {header: 'User', use_as: 'new_field', kind: 'user', code: 'new_user'},
      {header: 'Email', use_as: 'new_field', kind: 'email', code: 'new_email'},
      {header: 'Phone', use_as: 'new_field', kind: 'phone', code: 'new_phone'},
    ]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(2)

    new_layer = layers.detect{|l| l.name == "Import wizard"}

    fields = new_layer.fields
    expect(fields.length).to eq(10)

    sites = collection.sites.reload
    expect(sites.length).to eq(2)

    site1.reload
    expect(site1.name).to eq('Foo new')
    expect(site1.properties.length).to eq(10)
    expect(site1.properties[yes_no.es_code]).to be_falsey

    site2.reload
    expect(site2.name).to eq('Bar old')
    expect(site2.properties).to eq({})
  end

  it "should guess column spec for existing fields" do
    email_field = layer.email_fields.make :code => 'email'

    csv_string = CSV.generate do |csv|
     csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'text', 'numeric', 'select_one', 'select_many', 'hierarchy', 'site', 'date', 'user', 'email']
     csv << ["123", 'Foo old', '1.2', '3.4', '', '', 'two', 'two', 'uno',  1235, '12/26/1988', 'user2@email.com', 'email@mail.com']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection

    expect(column_spec.length).to eq(13)

    expect(column_spec).to include({:header=>"resmap-id", :kind=> :id, :use_as=>:id, :id_matching_column=>'resmap-id'})
    expect(column_spec).to include({:header=>"Name", :kind=>:name, :use_as=>:name})
    expect(column_spec).to include({:header=>"Lat", :kind=>:location, :use_as=>:lat})
    expect(column_spec).to include({:header=>"Lon", :kind=>:location, :use_as=>:lng})
    expect(column_spec).to include({:header=>"text", :kind=>:text, :code=>"text", :label=>"Text", :use_as=>:existing_field, :field_id=>text.id, :layer_id=>layer.id})
    expect(column_spec).to include({:header=>"numeric", :kind=>:numeric, :code=>"numeric", :label=>"Numeric", :use_as=>:existing_field, :field_id=>numeric.id, :layer_id=>layer.id})
    expect(column_spec).to include({:header=>"select_one", :kind=>:select_one, :code=>"select_one", :label=>"Select One", :use_as=>:existing_field, :field_id=>select_one.id, :layer_id=>layer.id})
    expect(column_spec).to include({:header=>"select_many", :kind=>:select_many, :code=>"select_many", :label=>"Select Many", :use_as=>:existing_field, :field_id=>select_many.id, :layer_id=>layer.id})
    expect(column_spec).to include({:header=>"hierarchy", :kind=>:hierarchy, :code=>"hierarchy", :label=>"Hierarchy", :use_as=>:existing_field, :field_id=>hierarchy.id, :layer_id=>layer.id})
    expect(column_spec).to include({:header=>"site", :kind=>:site, :code=>"site", :label=>"Site", :use_as=>:existing_field, :field_id=>site.id, :layer_id=>layer.id})
    expect(column_spec).to include({:header=>"date", :kind=>:date, :code=>"date", :label=>"Date", :use_as=>:existing_field, :field_id=>date.id, :layer_id=>layer.id})
    expect(column_spec).to include({:header=>"user", :kind=>:user, :code=>"user", :label=>"User", :use_as=>:existing_field, :field_id=>director.id, :layer_id=>layer.id})
    expect(column_spec).to include({:header=>"email", :kind=>:email, :code=>"email", :label=>"Email", :use_as=>:existing_field, :field_id=>email_field.id, :layer_id=>layer.id})

    ImportWizard.delete_files(user, collection)
  end


  it "should not fail when there is no data in the csv" do
    csv_string = CSV.generate do |csv|
      csv << ['text', 'numeric', 'select_one', 'select_many', 'hierarchy', 'site', 'date', 'user', 'email']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection
    processed_sites = (ImportWizard.validate_sites_with_columns user, collection, column_spec)
    sites_preview = processed_sites[:sites]
    expect(sites_preview.length).to eq(0)
  end

  it "should not fail when there is no data in the csv (2)" do
    csv_string = "resmap-id,name,lat,long,AddOn,last updated\n"
    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection
    processed_sites = (ImportWizard.validate_sites_with_columns user, collection, column_spec)
    sites_preview = processed_sites[:sites]
    expect(sites_preview.length).to eq(0)
  end

  it "should get sites & errors for invalid existing fields" do
    email_field = layer.email_fields.make :code => 'email'
    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235

    csv_string = CSV.generate do |csv|
      csv << ['text', 'numeric', 'select_one', 'select_many', 'hierarchy', 'site', 'date', 'user', 'email']
      csv << ['new val', '11', 'two', 'one', '60', '1235', '12/26/1988', 'user2@email.com', 'email@mail.com']
      csv << ['new val', 'invalid11', 'inval', '60, inv', 'inval', '999', '12/26', 'non-existing@email.com', 'email@ma@il.com']
      csv << ['new val', 'invalid11', 'inval', '60, inv', 'inval', '999', '12/26', 'non-existing@email.com', 'email@ma@il.com']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection
    processed_sites = (ImportWizard.validate_sites_with_columns user, collection, column_spec)
    sites_preview = processed_sites[:sites]

    expect(sites_preview.length).to eq(3)
    first_line = sites_preview.first
    expect(first_line).to eq([{:value=>"new val"}, {value: '11'}, {:value=>"two"}, {:value=>"one"}, {:value=>"60"},
      {:value=>"1235"}, {:value=>"12/26/1988"}, {:value=>"user2@email.com"}, {:value=>"email@mail.com"}])

    #Lines 2 and 3 are equals
    second_line = sites_preview.last
    expect(second_line).to  eq([{:value=>"new val"}, {:value=>"invalid11"}, {:value=>"inval"}, {:value=>"60, inv"}, {:value=>"inval"},
      {:value=>"999"}, {:value=>"12/26"}, {:value=>"non-existing@email.com"}, {:value=>"email@ma@il.com"}])

    sites_errors = processed_sites[:errors]

    data_errors = sites_errors[:data_errors]
    expect(data_errors.length).to eq(8)

    expect(data_errors[0][:description]).to eq("Some of the values in field 'numeric' (2nd column) are not valid for the type numeric.")
    expect(data_errors[0][:type]).to eq('numeric values')
    expect(data_errors[0][:column]).to eq(1)
    expect(data_errors[0][:rows]).to eq([1, 2])

    expect(data_errors[1][:description]).to eq("Some of the values in field 'select_one' (3rd column) don't match any existing option.")
    expect(data_errors[1][:column]).to eq(2)
    expect(data_errors[1][:type]).to eq('option values')
    expect(data_errors[1][:rows]).to eq([1, 2])

    expect(data_errors[2][:description]).to eq("Some of the values in field 'select_many' (4th column) don't match any existing option.")
    expect(data_errors[2][:column]).to eq(3)
    expect(data_errors[2][:type]).to eq('option values')
    expect(data_errors[2][:rows]).to eq([1, 2])

    expect(data_errors[3][:description]).to eq("Some of the values in field 'hierarchy' (5th column) don't exist in the corresponding hierarchy.")
    expect(data_errors[3][:column]).to eq(4)
    expect(data_errors[3][:type]).to eq('values that can be found in the defined hierarchy')
    expect(data_errors[3][:rows]).to eq([1, 2])

    expect(data_errors[4][:description]).to eq("Some of the values in field 'site' (6th column) don't match any existing site id in this collection.")
    expect(data_errors[4][:column]).to eq(5)
    expect(data_errors[4][:rows]).to eq([1, 2])

    expect(data_errors[5][:description]).to eq("Some of the values in field 'date' (7th column) are not valid for the type date.")
    expect(data_errors[5][:column]).to eq(6)
    expect(data_errors[5][:type]).to eq('dates')
    expect(data_errors[5][:rows]).to eq([1, 2])

    expect(data_errors[6][:description]).to eq("Some of the values in field 'user' (8th column) don't match any email address of a member of this collection.")
    expect(data_errors[6][:column]).to eq(7)
    expect(data_errors[6][:type]).to eq('email addresses')
    expect(data_errors[6][:rows]).to eq([1, 2])

    expect(data_errors[7][:description]).to eq("Some of the values in field 'email' (9th column) are not valid for the type email.")
    expect(data_errors[7][:column]).to eq(8)
    expect(data_errors[7][:type]).to eq('email addresses')
    expect(data_errors[7][:rows]).to eq([1, 2])

    ImportWizard.delete_files(user, collection)
  end

  it "should be include hints for format errors" do
    email_field = layer.email_fields.make :code => 'email'

    csv_string = CSV.generate do |csv|
      csv << ['numeric', 'date', 'email', 'hierarchy']
      csv << ['11', '12/26/1988', 'email@mail.com', '60']
      csv << ['invalid11', '23/1/234', 'email@ma@il.com', 'invalid']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection
    sites_errors = (ImportWizard.validate_sites_with_columns user, collection, column_spec)[:errors]

    data_errors = sites_errors[:data_errors]

    expect(data_errors[0][:example]).to eq("Values must be integers.")
    expect(data_errors[1][:example]).to eq("Example of valid date: 01/25/2013.")
    expect(data_errors[2][:example]).to eq("Example of valid email: myemail@resourcemap.com.")
    expect(data_errors[3][:example]).to eq("Some valid values for this hierarchy are: 60, 100, 101.")
  end

  it "should get sites & errors for invalid existing fields if field_id is string" do
    csv_string = CSV.generate do |csv|
      csv <<  ['Numeric']
      csv << ['invalid']
    end

     specs = [
       {header: 'Numeric', use_as: 'existing_field', field_id: "#{numeric.id}"},
     ]

     ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
     errors = (ImportWizard.validate_sites_with_columns user, collection, specs)[:errors]

     data_errors = errors[:data_errors]
     expect(data_errors.length).to eq(1)

  end

  it "should get error for invalid new fields" do
    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235

    csv_string = CSV.generate do |csv|
     csv << ['text', 'numeric', 'select_one', 'select_many', 'hierarchy', 'site', 'date', 'user', 'email']
     csv << ['new val', '11', 'two', 'one', 'Dad', '1235', '12/26/1988', 'user2@email.com', 'email@mail.com']
     csv << ['new val', 'invalid11', 'inval', 'Dad, inv', 'inval', '999', '12/26', 'non-existing@email.com', 'email@ma@il.com']
     csv << ['new val', 'invalid11', '', '', '', '', '12/26', '', 'email@ma@il.com']

    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

    column_spec = [
     {header: 'Text', use_as: 'new_field', kind: 'text', code: 'text2', label: 'text2'},
     {header: 'Numeric', use_as: 'new_field', kind: 'numeric', code: 'numeric2', label: 'numeric2'},
     {header: 'Select One', use_as: 'new_field', kind: 'select_one', code: 'select_one2', label: 'select_one2'},
     {header: 'Select Many', use_as: 'new_field', kind: 'select_many', code: 'select_many2', label: 'select_many2'},
     {header: 'Hierarchy', use_as: 'new_field', kind: 'hierarchy', code: 'hierarchy2', label: 'hierarchy2'},
     {header: 'Site', use_as: 'new_field', kind: 'site', code: 'site2', label: 'site2'},
     {header: 'Date', use_as: 'new_field', kind: 'date', code: 'date2', label: 'date2'},
     {header: 'User', use_as: 'new_field', kind: 'user', code: 'user2', label: 'user2'},
     {header: 'Email', use_as: 'new_field', kind: 'email', code: 'email2', label: 'email2'},
    ]

    sites = (ImportWizard.validate_sites_with_columns user, collection, column_spec)
    sites_preview = sites[:sites]

    expect(sites_preview.length).to eq(3)
    first_line = sites_preview.first
    expect(first_line).to eq([{:value=>"new val"}, {value: '11'}, {:value=>"two"}, {:value=>"one"}, {:value=>"Dad"},
      {:value=>"1235"}, {:value=>"12/26/1988"}, {:value=>"user2@email.com"}, {:value=>"email@mail.com"}])

    second_line = sites_preview[1]
    expect(second_line).to  eq([{:value=>"new val"}, {:value=>"invalid11"}, {:value=>"inval"}, {:value=>"Dad, inv"}, {:value=>"inval"},
      {:value=>"999"}, {:value=>"12/26"}, {:value=>"non-existing@email.com"}, {:value=>"email@ma@il.com"}])

    sites_errors = sites[:errors]

    expect(sites_errors[:hierarchy_field_found]).to eq([{:new_hierarchy_columns=>[4]}])
    expect(sites_errors[:duplicated_code]).to eq({})
    expect(sites_errors[:duplicated_label]).to eq({})
    expect(sites_errors[:existing_code]).to eq({})
    expect(sites_errors[:existing_label]).to eq({})

    data_errors = sites_errors[:data_errors]
    expect(data_errors.length).to eq(5)

    expect(data_errors[0][:description]).to eq("Some of the values in field 'Numeric' (2nd column) are not valid for the type numeric.")
    expect(data_errors[0][:column]).to eq(1)
    expect(data_errors[0][:rows]).to eq([1, 2])

    expect(data_errors[1][:description]).to eq("Some of the values in field 'Site' (6th column) don't match any existing site id in this collection.")
    expect(data_errors[1][:column]).to eq(5)
    expect(data_errors[1][:rows]).to eq([1])

    expect(data_errors[2][:description]).to eq("Some of the values in field 'Date' (7th column) are not valid for the type date.")
    expect(data_errors[2][:column]).to eq(6)
    expect(data_errors[2][:rows]).to eq([1, 2])

    expect(data_errors[3][:description]).to eq("Some of the values in field 'User' (8th column) don't match any email address of a member of this collection.")
    expect(data_errors[3][:column]).to eq(7)
    expect(data_errors[3][:rows]).to eq([1])

    expect(data_errors[4][:description]).to eq("Some of the values in field 'Email' (9th column) are not valid for the type email.")
    expect(data_errors[4][:column]).to eq(8)
    expect(data_errors[4][:rows]).to eq([1, 2])

    ImportWizard.delete_files(user, collection)
  end


  it "should not create fields with duplicated name or code" do
    layer.numeric_fields.make :code => 'new_field', :name => 'Existing field'

    csv_string = CSV.generate do |csv|
     csv << ['text']
     csv << ['new val']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

    column_spec = [
      {header: 'Text', use_as: 'new_field', kind: 'text', code: 'text', label: 'Non Existing field'},
    ]

    expect {ImportWizard.execute_with_entities(user, collection, column_spec)}.to raise_error(RuntimeError, "Can't save field from column Text: A field with code 'text' already exists in the layer named #{layer.name}")

    column_spec = [
     {header: 'Text', use_as: 'new_field', kind: 'text', code: 'newtext', label: 'Existing field'},
    ]

    expect {ImportWizard.execute_with_entities(user, collection, column_spec)}.to raise_error(RuntimeError, "Can't save field from column Text: A field with label 'Existing field' already exists in the layer named #{layer.name}")

    ImportWizard.delete_files(user, collection)
  end


  ['lat', 'lng', 'name', 'id'].each do |usage|
    it "should return validation errors when more than one column is selected to be #{usage}" do
      csv_string = CSV.generate do |csv|
      csv << ['col1', 'col2 ']
      csv << ['val', 'val']
      end

      column_specs = [
       {header: 'Column 1', use_as: "#{usage}"},
       {header: 'Column 2', use_as:"#{usage}"}
       ]

      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)

      sites_errors = sites_preview[:errors]
      expect(sites_errors[:duplicated_usage]).to eq("#{usage}" => [0,1])

      ImportWizard.delete_files(user, collection)
    end
  end

  it "should return validation errors when more than one column is selected to be the same existing field" do
    csv_string = CSV.generate do |csv|
      csv << ['col1', 'col2 ']
      csv << ['val', 'val']
    end

    column_specs = [
     {header: 'Column 1', use_as: "existing_field", field_id: text.id},
     {header: 'Column 2', use_as: "existing_field", field_id: text.id}
     ]

     ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

     sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)
     sites_errors = sites_preview[:errors]
     expect(sites_errors[:duplicated_usage]).to eq(text.id => [0,1])

     ImportWizard.delete_files(user, collection)
  end


  it "should not return duplicated_usage validation errror when there is more than one column with usage 'ignore'" do
    csv_string = CSV.generate do |csv|
      csv << ['col1', 'col2 ']
      csv << ['val', 'val']
    end

    column_specs = [
     {header: 'Column 1', use_as: "ignore"},
     {header: 'Column 2', use_as: "ignore"}
     ]

     ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

     sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)

     sites_errors = sites_preview[:errors]
     expect(sites_errors[:duplicated_usage]).to eq({})

    ImportWizard.delete_files(user, collection)

  end

  ['code', 'label'].each do |value|
    it "should return validation errors when there is new_fields with duplicated #{value}" do
      csv_string = CSV.generate do |csv|
        csv << ['col1', 'col2 ']
        csv << ['val', 'val']
      end

     column_specs = [
       {header: 'Column 1', use_as: 'new_field', kind: 'select_one', "#{value}" => "repeated" },
       {header: 'Column 2', use_as: 'new_field', kind: 'select_one', "#{value}" => "repeated" }
       ]

      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)

      sites_errors = sites_preview[:errors]
      key = "duplicated_#{value}".to_sym
      expect(sites_errors[key]).to eq("repeated" => [0,1])
      ImportWizard.delete_files(user, collection)

    end
  end

  ['code', 'label'].each do |value|
    it "should return validation errors when there is existing_field with duplicated #{value}" do
      if value == 'label'
        repeated = layer.text_fields.make "name" => "repeated"
      else
        repeated = layer.text_fields.make "#{value}" => "repeated"
      end

      csv_string = CSV.generate do |csv|
        csv << ['col1', 'col2 ']
        csv << ['val', 'val']
      end

       column_specs = [
         {header: 'Column 1', use_as: 'new_field', kind: 'select_one', "#{value}" => "repeated" },
         {header: 'Column 2', use_as: 'new_field', kind: 'select_one', "#{value}" => "repeated" }
         ]

      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)

      sites_errors = sites_preview[:errors]
      key = "existing_#{value}".to_sym
      expect(sites_errors[key]).to eq("repeated" => [0,1])
      ImportWizard.delete_files(user, collection)

    end
  end

  it "should not show errors if usage is ignore" do

    csv_string = CSV.generate do |csv|
       csv << ['numeric ']
       csv << ['11']
       csv << ['invalid11']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

    columns_spec = [{header: 'numeric', use_as: 'ignore', kind: 'ignore'}]
    validated_sites = (ImportWizard.validate_sites_with_columns user, collection, columns_spec)

    sites_preview = validated_sites[:sites]
    expect(sites_preview).to  eq([[{:value=>"11"}], [{:value=>"invalid11"}]])
    sites_errors = validated_sites[:errors]

    expect(sites_errors[:data_errors]).to eq([])

    ImportWizard.delete_files(user, collection)
  end

  it "should not generate a data error when updating a default property" do
    site1 = collection.sites.make name: 'Foo old'

    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name']
      csv << ["#{site1.id}", 'Foo new']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id', kind: 'id'},
      {header: 'Name', use_as: 'name', kind: 'name'}]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
    sites_errors = sites_preview[:errors]
    expect(sites_errors[:data_errors]).to eq([])

    ImportWizard.delete_files(user, collection)
  end

  # Otherwise a missmatch will be generated
  it 'should not bypass columns with an empty value in the first row' do
    csv_string = CSV.generate do |csv|
      csv << ['0', '' , '']
      csv << ['1', '0', 'label2']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection

    expect(column_spec.length).to eq(3)
    expect(column_spec[1][:header]).to eq("")
    expect(column_spec[1][:code]).to eq("")
    expect(column_spec[1][:label]).to eq("")
    expect(column_spec[1][:use_as]).to eq(:new_field)
    expect(column_spec[2][:header]).to eq("")
    expect(column_spec[2][:code]).to eq("")
    expect(column_spec[2][:label]).to eq("")
    expect(column_spec[2][:use_as]).to eq(:new_field)

    ImportWizard.delete_files(user, collection)
  end

  it 'should not fail if header has a nil value' do
    csv_string = CSV.generate do |csv|
      csv << ['0', nil , nil]
      csv << ['1', '0', 'label2']
    end

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    column_spec = ImportWizard.guess_columns_spec user, collection

    expect(column_spec.length).to eq(3)
    expect(column_spec[1][:header]).to eq("")
    expect(column_spec[1][:code]).to eq("")
    expect(column_spec[1][:label]).to eq("")
    expect(column_spec[1][:use_as]).to eq(:new_field)
    expect(column_spec[2][:header]).to eq("")
    expect(column_spec[2][:code]).to eq("")
    expect(column_spec[2][:label]).to eq("")
    expect(column_spec[2][:use_as]).to eq(:new_field)

    ImportWizard.delete_files(user, collection)
  end

  it 'should not fail if label and code are missing in new fields' do
    csv_string = CSV.generate do |csv|
      csv << ['0', '' , '']
      csv << ['1', '0', 'label2']
    end

    specs = [
      {:header=>"0", :kind=>:numeric, :code=>"0", :label=>"0", :use_as=>:new_field},
      {:header=>"", :kind=>:text, :code=>"", :label=>"", :use_as=>:new_field},
      {:header=>"", :kind=>:text, :code=>"", :label=>"", :use_as=>:new_field}]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
    sites_errors = sites_preview[:errors]
    expect(sites_errors[:missing_label]).to eq(:columns => [1,2])
    expect(sites_errors[:missing_code]).to eq(:columns => [1,2])

    ImportWizard.delete_files(user, collection)
  end

  it "should validate presence of name in column specs" do
    csv_string = CSV.generate do |csv|
      csv << ['numeric']
      csv << ['11']
    end

    specs = [{:header=>"numeric", :kind=>:numeric, :code=>"numeric", :label=>"numeric", :use_as=>:new_field}]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
    sites_errors = sites_preview[:errors]
    expect(sites_errors[:missing_name]).not_to be_blank

    ImportWizard.delete_files(user, collection)


    specs = [{:header=>"numeric", :use_as=>:name}]

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
    sites_errors = sites_preview[:errors]
    expect(sites_errors[:missing_name]).to be_blank

    ImportWizard.delete_files(user, collection)

  end

  Field.reserved_codes().each do |reserved_code|
    it "should validate reserved code #{reserved_code} in new fields" do
      csv_string = CSV.generate do |csv|
        csv << ["#{reserved_code}"]
        csv << ['11']
      end

      specs = [{:header=>"#{reserved_code}", :kind=>:text, :code=>"#{reserved_code}", :label=>"Label", :use_as=>:new_field}]

      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
      sites_errors = sites_preview[:errors]
      expect(sites_errors[:reserved_code]).to eq({"#{reserved_code}"=>[0]})
      ImportWizard.delete_files(user, collection)

    end
  end

  it "should validate ids belong to collection's sites if a column is marked to be used as 'id'" do
    csv_string = CSV.generate do |csv|
      csv << ["resmap-id"]
      csv << ['']
      csv << ['11']
    end

    specs = [{:header=>"resmap-id", :use_as=>:id}]
    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
    sites_errors = sites_preview[:errors]

    expect(sites_errors[:non_existent_site_id].length).to eq(1)
    resmap_id_error = sites_errors[:non_existent_site_id][0]
    expect(resmap_id_error[:rows]).to eq([1])
    expect(resmap_id_error[:column]).to eq(0)
    ImportWizard.delete_files(user, collection)

  end

  it "should not show errors for valid sites ids(numeric or text)" do
    site1 = collection.sites.make name: 'Bar'
    site2 = collection.sites.make name: 'Foo'

    csv_string = CSV.generate do |csv|
      csv << ["resmap-id"]
      csv << ["#{site1.id}"]
      csv << [site2.id]
    end

    specs = [{:header=>"resmap-id", :use_as=>:id}]
    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, specs)
    sites_errors = sites_preview[:errors]

    expect(sites_errors[:non_existent_site_id]).to be(nil)
    ImportWizard.delete_files(user, collection)

  end

  it "shouldn't fail with blank lines at the end" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Lat', 'Lon', 'Beds']
      csv << ['Foo', '1.2', '3.4', '10']
      csv << ['Bar', '5.6', '7.8', '20']
      csv << []
      csv << []
      csv << []
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'},
      {header: 'Beds', use_as: 'new_field', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    ImportWizard.import user, collection, 'foo.csv', csv_string
    ImportWizard.mark_job_as_pending user, collection

    column_spec = ImportWizard.guess_columns_spec user, collection
    sites_errors = (ImportWizard.validate_sites_with_columns user, collection, column_spec)[:errors]
    # do nothing (the test is that it shouldn't raise)
  end

  it "should not import files with invalid extension" do
    with_tmp_file('example.txt') do |tmp_file|

      File.open(tmp_file, "w") do |f|
        f.write("one, two")
      end
      expect { ImportWizard.import user, collection, 'example.txt', "one, two" }.to raise_error
    end

  end

  it "should not import malformed csv files" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', '2']
      csv << ['Foo', '1.2', '3.4', '10']
    end
    expect { ImportWizard.import user, collection, 'foo.csv', csv_string }.to raise_error
  end

  it "should not fail when there is latin1 characters" do
    csv_string = CSV.open("utf8.csv", "wb", encoding: "ISO-8859-1") do |csv|
      csv << ["é", "ñ", "ç", "ø"]
      csv << ["é", "ñ", "ç", "ø"]
    end

    specs = [
      {header: 'é', use_as: 'name'},
      {header: 'ñ', use_as: 'new_field', kind: 'text', code: 'text1', label: 'text 1'},
      {header: 'ç', use_as: 'new_field', kind: 'text', code: 'text2', label: 'text 2'},
      {header: 'ø', use_as: 'new_field', kind: 'text', code: 'text3', label: 'text 3'}
      ]

    expect { ImportWizard.import user, collection, 'utf8.csv', csv_string }.to_not raise_error
    expect { ImportWizard.mark_job_as_pending user, collection }.to_not raise_error
    expect { column_spec = ImportWizard.guess_columns_spec user, collection}.to_not raise_error
    column_spec = ImportWizard.guess_columns_spec user, collection
    expect {ImportWizard.validate_sites_with_columns user, collection, column_spec}.to_not raise_error
    File.delete('utf8.csv')
  end

  describe 'updates' do
    it 'only some fields of a valid site in a collection with one or more select one fields' do
      # The collection has a valid site before the import
      site1 = collection.sites.make name: 'Foo old', properties: {text.es_code => 'coco', select_one.es_code => 1}

      # User uploads a CSV with only the resmap-id, name and text fields set.
      # At the time of writing (1 Jul 2013), this causes the import to fail.
      csv_string = CSV.generate do |csv|
        csv << ['resmap-id', 'Name', text.name]
        csv << [site1.id, 'Foo old', 'coco2']
      end

      specs = [
        {header: 'resmap-id', use_as: :id},
        {header: 'Name', use_as: 'name'},
        {header: text.name , use_as: 'existing_field', field_id: text.id},
      ]

      ImportWizard.import user, collection, 'foo.csv', csv_string
      ImportWizard.mark_job_as_pending user, collection

      ImportWizard.execute user, collection, specs
      sites = collection.sites.reload
      expect(sites.length).to eq(1)

      expect(sites[0].name).to eq('Foo old')
      expect(sites[0].properties[text.es_code]).to eq('coco2')
      expect(sites[0].properties[select_one.es_code]).to eq(1)
    end
  end

  describe "luhn values" do
    let!(:luhn_id) {layer.identifier_fields.make :code => 'moh-id', :config => {"context" => "MOH", "agency" => "DHIS", "format" => "Luhn"} }

    it "should generate default luhn values when the column is not present and there is no data" do
      csv_string = CSV.generate do |csv|
        csv << ['Name']
        csv << ['Foo']
      end

      specs = [
        {header: 'Name', use_as: 'name'}
      ]

      ImportWizard.import user, collection, 'foo.csv', csv_string
      ImportWizard.mark_job_as_pending user, collection

      ImportWizard.execute user, collection, specs
      sites = collection.sites.reload
      expect(sites.length).to eq(1)

      expect(sites[0].name).to eq('Foo')
      expect(sites[0].properties[luhn_id.es_code]).to eq('100000-9')
    end

    it "should create a site with an especific luhn value and one with a default value" do
      csv_string = CSV.generate do |csv|
        csv << ['Name', 'moh-id']
        csv << ['Foo', '100002-5']
        csv << ['Foo 2', '']
      end

      specs = [
        {header: 'Name', use_as: 'name'},
        {header: 'moh-id' , use_as: 'existing_field', field_id: luhn_id.id},
      ]

      ImportWizard.import user, collection, 'foo.csv', csv_string
      ImportWizard.mark_job_as_pending user, collection

      ImportWizard.execute user, collection, specs
      sites = collection.sites.reload
      expect(sites.length).to eq(2)

      expect(sites[0].name).to eq('Foo')
      expect(sites[0].properties[luhn_id.es_code]).to eq('100002-5')

      expect(sites[1].name).to eq('Foo 2')
      expect(sites[1].properties[luhn_id.es_code]).to eq('100000-9')
    end

    it "should not override existing luhn value when updating a site" do
      site1 = collection.sites.make name: 'Foo', properties: {luhn_id.es_code => '100001-7'}

      csv_string = CSV.generate do |csv|
        csv << ['resmap-id', 'Name']
        csv << [site1.id, 'Foo new']
      end

      specs = [
        {header: 'resmap-id', use_as: :id},
        {header: 'Name', use_as: 'name'},
      ]

      ImportWizard.import user, collection, 'foo.csv', csv_string
      ImportWizard.mark_job_as_pending user, collection

      ImportWizard.execute user, collection, specs
      sites = collection.sites.reload
      expect(sites.length).to eq(1)

      expect(sites[0].name).to eq('Foo new')
      expect(sites[0].properties[luhn_id.es_code]).to eq('100001-7')
    end

    it "should choose the higher luhn between the one alredy stored in the collection and the one in the csv for the default value for new sites" do
      site1 = collection.sites.make name: 'Foo', properties: {luhn_id.es_code => '100001-7'}

      csv_string = CSV.generate do |csv|
        csv << ['Name', 'Luhn']
        csv << ['Foo new 1', '']
        csv << ['Foo new 2', '100002-5']

      end

      specs = [
        {header: 'Name', use_as: 'name'},
        {header: 'Luhn' , use_as: 'existing_field', field_id: luhn_id.id},
      ]

      ImportWizard.import user, collection, 'foo.csv', csv_string
      ImportWizard.mark_job_as_pending user, collection

      ImportWizard.validate_sites_with_columns user, collection, specs
      ImportWizard.execute user, collection, specs
      sites = collection.sites.reload
      expect(sites.length).to eq(3)

      expect(sites[0].name).to eq('Foo')
      expect(sites[0].properties[luhn_id.es_code]).to eq('100001-7')

      expect(sites[1].name).to eq('Foo new 1')
      expect(sites[1].properties[luhn_id.es_code]).to eq('100003-3')

      expect(sites[2].name).to eq('Foo new 2')
      expect(sites[2].properties[luhn_id.es_code]).to eq('100002-5')
    end


    it "should not repeat an existing value for new sites" do
      site1 = collection.sites.make name: 'Foo', properties: {luhn_id.es_code => '100001-7'}

      csv_string = CSV.generate do |csv|
        csv << ['Name']
        csv << ['Foo 2']
      end

      specs = [
        {header: 'Name', use_as: 'name'},
      ]

      ImportWizard.import user, collection, 'foo.csv', csv_string
      ImportWizard.mark_job_as_pending user, collection

      ImportWizard.execute user, collection, specs
      sites = collection.sites.reload
      expect(sites.length).to eq(2)

      expect(sites[0].name).to eq('Foo')
      expect(sites[0].properties[luhn_id.es_code]).to eq('100001-7')

      expect(sites[1].name).to eq('Foo 2')
      expect(sites[1].properties[luhn_id.es_code]).to eq('100002-5')
    end
  end

  describe "auto_reset" do
    let!(:auto_reset) { layer.yes_no_fields.make :code => 'flag', :config => { 'auto_reset' => true } }

    it "should reset sites included despite the values used in the import only if changed" do
      site1 = collection.sites.make name: 'Foo', properties: {auto_reset.es_code => true}
      site2 = collection.sites.make name: 'Bar', properties: {auto_reset.es_code => true}
      site3 = collection.sites.make name: 'Old', properties: {auto_reset.es_code => true}
      site4 = collection.sites.make name: 'Lorem', properties: {auto_reset.es_code => false}
      site5 = collection.sites.make name: 'Ipsum', properties: {auto_reset.es_code => true}

      csv_string = CSV.generate do |csv|
        csv << ['resmap-id', 'Name', 'Column']
        csv << [site1.id,'Foo', 'true']
        csv << [site2.id,'Bar', 'false']
        csv << [site4.id,'Lorem', 'true']
        csv << [site5.id,'Ipsum2', 'true']
        csv << ['','Baz', 'true']
        csv << ['','Foobar', 'false']
        csv << ['','', '']
      end

      specs = [
        {header: 'resmap-id', use_as: 'id'},
        {header: 'Name', use_as: 'name'},
        {header: 'Column', use_as: 'existing_field', field_id: auto_reset.id},
        ]

      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
      ImportWizard.execute user, collection, specs

      expect(collection.layers).to eq([layer])

      sites = collection.sites.reload
      expect(sites.length).to eq(7)

      expect(sites[0].name).to eq('Foo')
      expect(sites[0].properties).to eq({auto_reset.es_code => false})

      expect(sites[1].name).to eq('Bar')
      expect(sites[1].properties).to eq({auto_reset.es_code => false})

      expect(sites[2].name).to eq('Old')
      expect(sites[2].properties).to eq({auto_reset.es_code => true})

      expect(sites[3].name).to eq('Lorem')
      expect(sites[3].properties).to eq({auto_reset.es_code => false})

      expect(sites[4].name).to eq('Ipsum2')
      expect(sites[4].properties).to eq({auto_reset.es_code => false})

      expect(sites[5].name).to eq('Baz')
      expect(sites[5].properties).to eq({auto_reset.es_code => false})

      expect(sites[6].name).to eq('Foobar')
      expect(sites[6].properties).to eq({auto_reset.es_code => false})
    end
  end


  describe "PKs for update" do
    let(:moh_id) {layer.identifier_fields.make :code => 'moh-id', :config => {"context" => "MOH", "agency" => "DHIS", "format" => "Normal"} }
    let(:other_id) { layer.identifier_fields.make :code => 'other-id', :config => {"context" => "MOH", "agency" => "Jembi", "format" => "Normal"} }

    it "should not allow two PK pivots columns" do
      csv_string = CSV.generate do |csv|
        csv << ['col1', 'col2 ']
        csv << ['val', 'val']
      end

      column_specs = [
        {header: 'Column 1', use_as: "id", id_matching_column: "resmap-id"},
        {header: 'Column 2', use_as:"id", id_matching_column: moh_id.id.to_s}
      ]

      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)

      sites_errors = sites_preview[:errors]
      expect(sites_errors[:duplicated_usage]).to eq("id" => [0,1])

      ImportWizard.delete_files(user, collection)
    end

    it "uploading an empty value as identifier field PK should be invalid" do
      collection.sites.make properties: {moh_id.es_code => '123'}

      csv_string = CSV.generate do |csv|
        csv << ['moh-id', 'name ']
        csv << ['456', 'Name']
        csv << ['', 'Name 2']
        csv << ['123', 'Name 2']
      end

      column_specs = [
        {header: 'moh-id', use_as: "id", id_matching_column: moh_id.id.to_s},
        {header: 'name', use_as: "name"}
      ]
      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)
      sites_errors = sites_preview[:errors]

      expect(sites_errors[:invalid_site_identifier]).to eq([{:rows=>[1], :column=>0}])
    end

    it "should not show validation error in other luhn fields the pivot is an identifier" do
      site = collection.sites.make properties: {moh_id.es_code => '123', other_id.es_code => '456'}

      csv_string = CSV.generate do |csv|
        csv << ['moh-id', 'name ', 'other-id']
        csv << ['123', site.name,  '456']
      end

      column_specs = [
        {header: 'moh-id', use_as: "id", id_matching_column: moh_id.id.to_s},
        {header: 'name', use_as: "name"},
        {header: 'other-id', use_as: "existing_field", field_id: other_id.id.to_s},

      ]
      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)
      sites_errors = sites_preview[:errors]
      data_errors = sites_errors[:data_errors]
      expect(data_errors.length).to eq(0)

      expect(sites_errors[:invalid_site_identifier]).to be_nil
    end

    it "should show validation error in other if a value already exists for an exisiting luhn value" do
      site = collection.sites.make properties: {moh_id.es_code => '123', other_id.es_code => '456'}
      site2 = collection.sites.make properties: {other_id.es_code => '457'}

      csv_string = CSV.generate do |csv|
        csv << ['moh-id', 'name ', 'other-id']
        csv << ['123', site.name,  '457']
      end

      column_specs = [
        {header: 'moh-id', use_as: "id", id_matching_column: moh_id.id.to_s},
        {header: 'name', use_as: "name"},
        {header: 'other-id', use_as: "existing_field", field_id: other_id.id.to_s},

      ]
      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)
      sites_errors = sites_preview[:errors]
      data_errors = sites_errors[:data_errors]
      expect(data_errors.length).to eq(1)

      expect(sites_errors[:invalid_site_identifier]).to be_nil
    end

    it "should import using an identifier field as pivot" do
      collection.sites.make properties: {moh_id.es_code => '123', other_id.es_code => '456'}

      csv_string = CSV.generate do |csv|
        csv << ['moh-id', 'name ', 'other-id']
        csv << ['123', "Changed Name",  '457']
      end

      column_specs = [
        {header: 'moh-id', use_as: "id", id_matching_column: moh_id.id.to_s},
        {header: 'name', use_as: "name"},
        {header: 'other-id', use_as: "existing_field", field_id: other_id.id.to_s},
      ]

      ImportWizard.import user, collection, 'foo.csv', csv_string
      ImportWizard.mark_job_as_pending user, collection
      ImportWizard.execute user, collection, column_specs

      sites = collection.sites.reload
      expect(sites.length).to eq(1)

      expect(sites[0].name).to eq('Changed Name')
      expect(sites[0].properties).to eq({moh_id.es_code => '123', other_id.es_code => '457'})
    end

    it "should import using an identifier field without changing the value for an another identifier field" do
      collection.sites.make properties: {moh_id.es_code => '123', other_id.es_code => '456'}

      csv_string = CSV.generate do |csv|
        csv << ['moh-id', 'name ', 'other-id']
        csv << ['123', "Changed Name",  '456']
      end

      column_specs = [
        {header: 'moh-id', use_as: "id", id_matching_column: moh_id.id.to_s},
        {header: 'name', use_as: "name"},
        {header: 'other-id', use_as: "existing_field", field_id: other_id.id.to_s},
      ]

      ImportWizard.import user, collection, 'foo.csv', csv_string
      ImportWizard.mark_job_as_pending user, collection
      ImportWizard.execute user, collection, column_specs

      sites = collection.sites.reload
      expect(sites.length).to eq(1)

      expect(sites[0].name).to eq('Changed Name')
      expect(sites[0].properties).to eq({moh_id.es_code => '123', other_id.es_code => '456'})
    end

    it "should create new site if the value for the identifier Pivot column does not exist" do
      collection.sites.make properties: {moh_id.es_code => '123', other_id.es_code => '456'}

      csv_string = CSV.generate do |csv|
        csv << ['moh-id', 'name ', 'other-id']
        csv << ['1', "New",  '2']
      end

      column_specs = [
        {header: 'moh-id', use_as: "id", id_matching_column: moh_id.id.to_s},
        {header: 'name', use_as: "name"},
        {header: 'other-id', use_as: "existing_field", field_id: other_id.id.to_s},
      ]

      ImportWizard.import user, collection, 'foo.csv', csv_string
      ImportWizard.mark_job_as_pending user, collection
      ImportWizard.execute user, collection, column_specs

      sites = collection.sites.reload
      expect(sites.length).to eq(2)

      expect(sites[1].name).to eq('New')
      expect(sites[1].properties).to eq({moh_id.es_code => '1', other_id.es_code => '2'})
    end

    describe "guess" do

      it "should guess resmap-id column as pivot if it is present" do
        site = collection.sites.make properties: {moh_id.es_code => '123', other_id.es_code => '456'}

        csv_string = CSV.generate do |csv|
          csv << ['resmap-id', 'moh-id', 'name', 'other-id']
          csv << [site.id, '123', site.name,  '456']
        end

        ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
        column_spec = ImportWizard.guess_columns_spec user, collection
        expect(column_spec).to include({:header=>"resmap-id", :kind=> :id, :use_as=>:id, :id_matching_column=>'resmap-id'})
        expect(column_spec).to include({:header=>"name", :kind=>:name, :use_as=>:name})
        #TODO: label should be "Other Id" or "Moh Id" and not only "Other" or "Moh"
        expect(column_spec).to include({:header=>"other-id", :use_as=>:existing_field, :code=>"other-id", :label=>"Other", :kind=> :identifier, :field_id => other_id.id, :layer_id=>layer.id})
        expect(column_spec).to include({:header=>"moh-id", :use_as=>:existing_field, :code=>"moh-id", :label=>"Moh", :kind=> :identifier, :field_id => moh_id.id, :layer_id=>layer.id})

        ImportWizard.delete_files(user, collection)
      end

      it "should guess the first identifier column as pivot if resmap-id is not present" do
        site = collection.sites.make properties: {moh_id.es_code => '123', other_id.es_code => '456'}

        csv_string = CSV.generate do |csv|
          csv << ['moh-id', 'name', 'other-id']
          csv << ['123', site.name,  '456']
        end

        ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
        column_spec = ImportWizard.guess_columns_spec user, collection
        expect(column_spec).to include({:header=>"name", :kind=>:name, :use_as=>:name})
        expect(column_spec).to include({:header=>"moh-id", :use_as=>:id, :id_matching_column=>moh_id.id})
        expect(column_spec).to include({:header=>"other-id", :use_as=>:existing_field, :code=>"other-id", :label=>"Other", :kind=> :identifier, :field_id => other_id.id, :layer_id=>layer.id})

        ImportWizard.delete_files(user, collection)
      end
    end

    it "when the pivot value does not exist, an existing 'identifier' value should be invalid" do
      site = collection.sites.make properties: {moh_id.es_code => '123', other_id.es_code => '456'}

      csv_string = CSV.generate do |csv|
        csv << ['moh-id', 'name', 'other-id']
        csv << ['new-one', site.name,  '456']
      end

      column_specs = [
        {header: 'moh-id', use_as: "id", id_matching_column: moh_id.id.to_s},
        {header: 'name', use_as: "name"},
        {header: 'other-id', use_as: "existing_field", field_id: other_id.id.to_s},
      ]

      ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection

      sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_specs)
      sites_errors = sites_preview[:errors]
      data_errors = sites_errors[:data_errors]
      expect(data_errors.length).to eq(1)

      expect(data_errors.first[:description]).to eq "Some of the values in field 'other-id' (3rd column) are not valid for the type identifier: The value already exists in the collection."
    end
  end
end
