require 'spec_helper'

describe ImportWizard, :type => :model do
  let(:user) { User.make }
  let(:collection) { user.create_collection Collection.make_unsaved }
  let(:layer) { collection.layers.make }

  let(:phone) { layer.phone_fields.make :code => 'phone' }
  let(:email) { layer.email_fields.make :code => 'email' }

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

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(1)
    expect(layers[0].name).to eq(layer.name)

    fields = layers[0].fields
    expect(fields.length).to eq(2)

    sites = collection.sites
    expect(sites.length).to eq(2)

    site1.reload
    expect(site1.name).to eq('Foo new')
    expect(site1.properties).to eq({
      phone.es_code => '855111111111',
      email.es_code => 'new@email.com'
    })

    site2.reload
    expect(site2.name).to eq('Bar old')
    expect(site2.properties).to eq({phone.es_code => '855123456789'})
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

    ImportWizard.import user, collection, 'foo.csv', csv_string; ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    layers = collection.layers
    expect(layers.length).to eq(1)
    expect(layers[0].name).to eq(layer.name)

    fields = layers[0].fields
    expect(fields.length).to eq(2)

    sites = collection.sites
    expect(sites.length).to eq(2)

    site1.reload
    expect(site1.name).to eq('Foo old')
    expect(site1.properties).to eq({})

    site2.reload
    expect(site2.name).to eq('Bar old')
    expect(site2.properties).to eq({phone.es_code => '855123456789'})
  end
end
