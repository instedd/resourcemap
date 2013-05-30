require 'spec_helper'

describe ImportWizard do
  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }
  let!(:layer) { collection.layers.make }

  let!(:phone) { layer.phone_fields.make :code => 'phone' }
  let!(:email) { layer.email_fields.make :code => 'email' }

  it "should update all property values" do
    site1 = collection.sites.make name: 'Foo old', properties: {
      phone.es_code => '855123456789',
      email.es_code => 'mail@mail.com'
    }

    site2 = collection.sites.make name: 'Bar old', properties: {phone.es_code => '855123456789'}


    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'phone', 'email']
      csv << ["#{site1.id}", 'Foo new', '1.2', '3.4', '855111111111', 'new@email.com']
    end

    specs = [
      {header: 'resmap-id', use_as: 'id'},
      {header: 'Name', use_as: 'name'},
      {header: 'phone', use_as: 'existing_field', field_id: phone.id},
      {header: 'email', use_as: 'existing_field', field_id: email.id}
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(1)
    layers[0].name.should eq(layer.name)

    fields = layers[0].fields.all
    fields.length.should eq(2)

    sites = collection.sites.all
    sites.length.should eq(2)

    site1.reload
    site1.name.should eq('Foo new')
    site1.properties.should eq({
      phone.es_code => '855111111111',
      email.es_code => 'new@email.com'
    })

    site2.reload
    site2.name.should eq('Bar old')
    site2.properties.should eq({phone.es_code => '855123456789'})
  end
  
  it "should delete all property values" do
    site1 = collection.sites.make name: 'Foo old', properties: {
      phone.es_code => '855123456789',
      email.es_code => 'mail@mail.com'
    }

    site2 = collection.sites.make name: 'Bar old', properties: {phone.es_code => '855123456789'}


    csv_string = CSV.generate do |csv|
      csv << ['resmap-id', 'Name', 'Lat', 'Lon', 'phone', 'email']
      csv << ["#{site1.id}", 'Foo old', '1.2', '3.4', '', '']
    end

   specs = [
      {header: 'resmap-id', use_as: 'id'},
      {header: 'Name', use_as: 'name'},
      {header: 'phone', use_as: 'existing_field', field_id: phone.id},
      {header: 'email', use_as: 'existing_field', field_id: email.id}
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(1)
    layers[0].name.should eq(layer.name)

    fields = layers[0].fields.all
    fields.length.should eq(2)

    sites = collection.sites.all
    sites.length.should eq(2)

    site1.reload
    site1.name.should eq('Foo old')
    site1.properties.should eq({})

    site2.reload
    site2.name.should eq('Bar old')
    site2.properties.should eq({phone.es_code => '855123456789'})
  end
end
