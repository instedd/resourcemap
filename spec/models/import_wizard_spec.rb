require 'spec_helper'

describe ImportWizard do
  let!(:user) { User.make }

  let!(:collection) { user.create_collection Collection.make_unsaved }
  let!(:user2) { collection.users.make :email => 'user2@email.com'}
  let!(:membership) { collection.memberships.create! :user_id => user2.id }

  let!(:layer) { collection.layers.make }

  let!(:text) { layer.fields.make :code => 'text', :kind => 'text' }
  let!(:numeric) { layer.fields.make :code => 'numeric', :kind => 'numeric' }
  let!(:select_one) { layer.fields.make :code => 'select_one', :kind => 'select_one', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  let!(:select_many) { layer.fields.make :code => 'select_many', :kind => 'select_many', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
  let!(:hierarchy) { layer.fields.make :code => 'hierarchy', :kind => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access }
  let!(:site) { layer.fields.make :code => 'site', :kind => 'site' }
  let!(:date) { layer.fields.make :code => 'date', :kind => 'date' }
  let!(:director) { layer.fields.make :code => 'user', :kind => 'user' }

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
        csv << ['Foo', 'Son']
        csv << ['Bar', 'Bro']
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
      sites[0].properties.should eq({hierarchy.es_code => "100"})

      sites[1].name.should eq('Bar')
      sites[1].properties.should eq({hierarchy.es_code => "101"})

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
      date.es_code => "2012-10-24T03:00:00.000Z",
      director.es_code => user.email
    }

    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235


    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Text', 'Numeric', 'Select One', 'Select Many', 'Hierarchy', 'Site', 'Date', 'User']
      csv << ["#{site1.id}", 'Foo new', '1.2', '3.4', 'new val', 11, 'two', 'two', 'Dad',  1235, '12/26/1988', 'user2@email.com']
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
      {name: 'User', usage: 'existing_field', field_id: director.id},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(1)
    layers[0].name.should eq(layer.name)

    fields = layers[0].fields.all
    fields.length.should eq(8)

    sites = collection.sites.all
    sites.length.should eq(2)

    site1.reload
    site1.name.should eq('Foo new')
    site1.properties.should eq({
      text.es_code => 'new val',
      numeric.es_code => 11,
      select_one.es_code => 2,
      select_many.es_code => [2],
      hierarchy.es_code => '60',
      site.es_code => '1235',
      date.es_code => "1988-12-26T00:00:00Z",
      director.es_code => 'user2@email.com'
    })

    site2.reload
    site2.name.should eq('Bar old')
    site2.properties.should eq({text.es_code => 'lala'})
  end

  it "should delete all property values" do
    site1 = collection.sites.make name: 'Foo old', id: 1234, properties: {
      text.es_code => 'coco',
      numeric.es_code => 10,
      select_one.es_code => 1,
      select_many.es_code => [1, 2],
      hierarchy.es_code => 60,
      site.es_code => 1234,
      date.es_code => "2012-10-24T03:00:00.000Z",
      director.es_code => user.email
    }

    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235

    csv_string = CSV.generate do |csv|
     csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Text', 'Numeric', 'Select One', 'Select Many', 'Hierarchy', 'Site', 'Date', 'User']
     csv << ["#{site1.id}", 'Foo old', '1.2', '3.4', '', '', '', '', '',  '', '', '']
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
     {name: 'User', usage: 'existing_field', field_id: director.id},
     ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(1)
    layers[0].name.should eq(layer.name)

    fields = layers[0].fields.all
    fields.length.should eq(8)

    sites = collection.sites.all
    sites.length.should eq(2)

    site1.reload
    site1.name.should eq('Foo old')
    site1.properties.should eq({})

    site2.reload
    site2.name.should eq('Bar old')
    site2.properties.should eq({text.es_code => 'lala'})
  end

  it "should not create a new hierarchy field in import wizard" do
    csv_string = CSV.generate do |csv|
      csv << ['Hierarchy']
      csv << ['Dad']
    end

    specs = [
      {name: 'Hierarchy', usage: 'new_field', kind: 'hierarchy', code: 'new_hierarchy'},
    ]

    ImportWizard.import user, collection, csv_string
    expect { ImportWizard.execute(user, collection, specs) }.to raise_error

  end

  it "should create new fields with all property values" do
    site1 = collection.sites.make name: 'Foo old', id: 1234, properties: {}

    site2 = collection.sites.make name: 'Bar old', properties: {}, id: 1235

    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'Text', 'Numeric', 'Select One', 'Select Many', 'Site', 'Date', 'User', 'Email', 'Phone']
      csv << ["#{site1.id}", 'Foo new', '1.2', '3.4', 'new val', 11, 'two', 'two, one',  1235, '12/26/1988', 'user2@email.com', 'new@email.com', '1456']
    end

    specs = [
      {name: 'resmap-id', usage: 'id'},
      {name: 'Name', usage: 'name'},
      {name: 'Text', usage: 'new_field', kind: 'text', code: 'new_text'},
      {name: 'Numeric', usage: 'new_field', kind: 'numeric', code: 'new_numeric'},
      {name: 'Select One', usage: 'new_field', kind: 'select_one', code: 'new_select_one', label: 'New Select One', selectKind: 'both'},
      {name: 'Select Many', usage: 'new_field', kind: 'select_many', code: 'new_select_many', label: 'New Select Many', selectKind: 'both'},
      {name: 'Site', usage: 'new_field', kind: 'site', code: 'new_site'},
      {name: 'Date', usage: 'new_field', kind: 'date', code: 'new_date'},
      {name: 'User', usage: 'new_field', kind: 'user', code: 'new_user'},
      {name: 'Email', usage: 'new_field', kind: 'email', code: 'new_email'},
      {name: 'Phone', usage: 'new_field', kind: 'phone', code: 'new_phone'},
    ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(2)

    new_layer = layers.detect{|l| l.name == "Import wizard"}

    fields = new_layer.fields.all
    fields.length.should eq(9)

    sites = collection.sites.all
    sites.length.should eq(2)

    site1.reload
    site1.name.should eq('Foo new')
    site1.properties.length.should eq(9)

    site2.reload
    site2.name.should eq('Bar old')
    site2.properties.should eq({})
  end

  it "should guess column spec for existing fields" do
    email_field = layer.fields.make :code => 'email', :kind => 'email'

    csv_string = CSV.generate do |csv|
     csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'text', 'numeric', 'select_one', 'select_many', 'hierarchy', 'site', 'date', 'user', 'email']
     csv << ["123", 'Foo old', '1.2', '3.4', '', '', 'two', 'two', 'uno',  1235, '12/26/1988', 'user2@email.com', 'email@mail.com']
    end

    ImportWizard.import user, collection, csv_string
    column_spec = ImportWizard.guess_columns_spec user, collection

    column_spec.length.should eq(13)

    column_spec.should include({:name=>"resmap-id", :kind=> :id, :code=>"resmap-id", :label=>"Resmap", :value=>"123", :usage=>:id})
    column_spec.should include({:name=>"Name", :kind=>:name, :code=>"name", :label=>"Name", :value=>"Foo old", :usage=>:name})
    column_spec.should include({:name=>"Lat", :kind=>:location, :code=>"lat", :label=>"Lat", :value=>"1.2", :usage=>:lat})
    column_spec.should include({:name=>"Lon", :kind=>:location, :code=>"lon", :label=>"Lon", :value=>"3.4", :usage=>:lng})
    column_spec.should include({:name=>"text", :kind=>:text, :code=>"text", :label=>"Text", :value=>"", :usage=>:existing_field, :layer_id=> text.layer_id, :field_id=>text.id})
    column_spec.should include({:name=>"numeric", :kind=>:numeric, :code=>"numeric", :label=>"Numeric", :value=>"", :usage=>:existing_field, :layer_id=>numeric.layer_id, :field_id=>numeric.id})
    column_spec.should include({:name=>"select_one", :kind=>:select_one, :code=>"select_one", :label=>"Select One", :value=>"two", :usage=>:existing_field, :layer_id=>select_one.layer_id, :field_id=>select_one.id})
    column_spec.should include({:name=>"select_many", :kind=>:select_many, :code=>"select_many", :label=>"Select Many", :value=>"two", :usage=>:existing_field, :layer_id=>select_many.layer_id, :field_id=>select_many.id})
    column_spec.should include({:name=>"hierarchy", :kind=>:hierarchy, :code=>"hierarchy", :label=>"Hierarchy", :value=>"uno", :usage=>:existing_field, :layer_id=>hierarchy.layer_id, :field_id=>hierarchy.id})
    column_spec.should include({:name=>"site", :kind=>:site, :code=>"site", :label=>"Site", :value=>"1235", :usage=>:existing_field, :layer_id=>site.layer_id, :field_id=>site.id})
    column_spec.should include({:name=>"date", :kind=>:date, :code=>"date", :label=>"Date", :value=>"12/26/1988", :usage=>:existing_field, :layer_id=>date.layer_id, :field_id=>date.id})
    column_spec.should include({:name=>"user", :kind=>:user, :code=>"user", :label=>"User", :value=>"user2@email.com", :usage=>:existing_field, :layer_id=>director.layer_id, :field_id=>director.id})
    column_spec.should include({:name=>"email", :kind=>:email, :code=>"email", :label=>"Email", :value=>"email@mail.com", :usage=>:existing_field, :layer_id=>email_field.layer_id, :field_id=>email_field.id})

    ImportWizard.delete_file(user, collection)
  end

  it "should get error for invalid existing fields" do
    email_field = layer.fields.make :code => 'email', :kind => 'email'
    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235

    csv_string = CSV.generate do |csv|
      csv << ['text', 'numeric', 'select_one', 'select_many', 'hierarchy', 'site', 'date', 'user', 'email']
      csv << ['new val', '11', 'two', 'one', 'Dad', '1235', '12/26/1988', 'user2@email.com', 'email@mail.com']
      csv << ['new val', 'invalid11', 'inval', 'Dad, inv', 'inval', '999', '12/26', 'non-existing@email.com', 'email@ma@il.com']
    end

    ImportWizard.import user, collection, csv_string
    column_spec = ImportWizard.guess_columns_spec user, collection
    sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_spec)[:sites]

    sites_preview.length.should eq(2)

    first_line = sites_preview.first
    first_line.should include({:value=>"new val", :error=>nil})
    first_line.should include({value: '11', error: nil})
    first_line.should include({:value=>"two", :error=>nil})
    first_line.should include({:value=>"one", :error=>nil})
    first_line.should include({:value=>"Dad", :error=>nil})
    first_line.should include({:value=>"1235", :error=>nil})
    first_line.should include({:value=>"12/26/1988", :error=>nil})
    first_line.should include({:value=>"user2@email.com", :error=>nil})
    first_line.should include({:value=>"email@mail.com", :error=>nil})

    second_line = sites_preview.last
    second_line.should include({:value=>"new val", :error=>nil})
    second_line.should include({:value=>"invalid11", :error=>"Invalid numeric value in numeric param"})
    second_line.should include({:value=>"inval", :error=>"Invalid option in select_one param"})
    second_line.should include({:value=>"Dad, inv", :error=>"Invalid option in select_many param"})
    second_line.should include({:value=>"inval", :error=>"Invalid option in hierarchy param"})
    second_line.should include({:value=>"999", :error=>"Non-existent site-id in site param"})
    second_line.should include({:value=>"non-existing@email.com", :error=>"Non-existent user-email in user param"})
    second_line.should include({:value=>"email@ma@il.com", :error=>"Invalid email value in email param"})

    ImportWizard.delete_file(user, collection)
  end

  it "should get error for invalid new fields" do
     site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235

     csv_string = CSV.generate do |csv|
       csv << ['text', 'numeric', 'select_one', 'select_many', 'hierarchy', 'site', 'date', 'user', 'email']
       csv << ['new val', '11', 'two', 'one', 'Dad', '1235', '12/26/1988', 'user2@email.com', 'email@mail.com']
       csv << ['new val', 'invalid11', 'inval', 'Dad, inv', 'inval', '999', '12/26', 'non-existing@email.com', 'email@ma@il.com']
     end

     ImportWizard.import user, collection, csv_string

     column_spec = [
       {name: 'Text', usage: 'new_field', kind: 'text', code: 'text'},
       {name: 'Numeric', usage: 'new_field', kind: 'numeric', code: 'numeric'},
       {name: 'Select One', usage: 'new_field', kind: 'select_one', code: 'select_one'},
       {name: 'Select Many', usage: 'new_field', kind: 'select_many', code: 'select_many'},
       {name: 'Hierarchy', usage: 'new_field', kind: 'hierarchy', code: 'hierarchy'},
       {name: 'Site', usage: 'new_field', kind: 'site', code: 'site'},
       {name: 'Date', usage: 'new_field', kind: 'date', code: 'date'},
       {name: 'User', usage: 'new_field', kind: 'user', code: 'user'},
       {name: 'Email', usage: 'new_field', kind: 'email', code: 'email'},
     ]

     sites_preview = (ImportWizard.validate_sites_with_columns user, collection, column_spec)[:sites]

     sites_preview.length.should eq(2)

     first_line = sites_preview.first
     first_line.should include({:value=>"new val", :error=>nil})
     first_line.should include({value: '11', error: nil})
     first_line.should include({:value=>"two", :error=>nil})
     first_line.should include({:value=>"one", :error=>nil})
     first_line.should include({:value=>"Dad", :error=> "Hierarchy fields can only be created via web in the Layers page"})
     first_line.should include({:value=>"1235", :error=>nil})
     first_line.should include({:value=>"12/26/1988", :error=>nil})
     first_line.should include({:value=>"user2@email.com", :error=>nil})
     first_line.should include({:value=>"email@mail.com", :error=>nil})

     second_line = sites_preview.last
     second_line.should include({:value=>"new val", :error=>nil})
     second_line.should include({:value=>"invalid11", :error=>"Invalid numeric value in numeric param"})
     #option will be created as news
     second_line.should include({:value=>"inval", :error=>nil})
     second_line.should include({:value=>"Dad, inv", :error=>nil})
     #hierarchy fields cannot be created using import wizard
     second_line.should include({:value=>"inval", :error=> "Hierarchy fields can only be created via web in the Layers page"})
     second_line.should include({:value=>"999", :error=>"Non-existent site-id in site param"})
     second_line.should include({:value=>"non-existing@email.com", :error=>"Non-existent user-email in user param"})
     second_line.should include({:value=>"email@ma@il.com", :error=>"Invalid email value in email param"})

     ImportWizard.delete_file(user, collection)
  end


  it "should not create fields with duplicated name or code" do
    layer.fields.make :code => 'new_field', :kind => 'numeric', :name => 'Existing field'

    csv_string = CSV.generate do |csv|
     csv << ['text']
     csv << ['new val']
    end

    ImportWizard.import user, collection, csv_string

    column_spec = [
      {name: 'Text', usage: 'new_field', kind: 'text', code: 'text', label: 'Non Existing field'},
    ]

    expect {ImportWizard.validate_columns collection, column_spec}.to raise_error(RuntimeError, "Can't save field from column Text: A field with code 'text' already exists in the layer named #{layer.name}")

    column_spec = [
     {name: 'Text', usage: 'new_field', kind: 'text', code: 'newtext', label: 'Existing field'},
    ]

    expect {ImportWizard.validate_columns collection, column_spec}.to raise_error(RuntimeError, "Can't save field from column Text: A field with label 'Existing field' already exists in the layer named #{layer.name}")
  end

  it "should validate only one column" do
    site2 = collection.sites.make name: 'Bar old', properties: {text.es_code => 'lala'}, id: 1235

     csv_string = CSV.generate do |csv|
       csv << ['text', 'numeric ', ' select_one', 'select_many ', ' hierarchy', 'site', 'date', 'user', 'email']
       csv << ['new val', '11', 'two', 'one', 'Dad', '1235', '12/26/1988', 'user2@email.com', 'email@mail.com']
       csv << ['new val', 'invalid11', 'inval', 'Dad, inv', 'inval', '999', '12/26', 'non-existing@email.com', 'email@ma@il.com']
     end

     ImportWizard.import user, collection, csv_string

     column_spec = {name: 'numeric', usage: 'new_field', kind: 'numeric', code: 'numeric'}
     sites_preview_one_column = (ImportWizard.validate_sites_with_column user, collection, column_spec)

     sites_preview_one_column[1].length.should eq(2)

     sites_preview_one_column[1].should include({value: '11', error: nil})
     sites_preview_one_column[1].should include({:value=>"invalid11", :error=>"Invalid numeric value in numeric param"})
  end

end
