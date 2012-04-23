require 'spec_helper'

describe ImportWizard do
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

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

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
    sites[0].properties.should eq({'beds' => 10})

    sites[1].name.should eq('Bar')
    sites[1].properties.should eq({'beds' => 20})
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

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(1)
    layers[0].name.should eq(collection.name)

    fields = layers[0].fields.all
    fields.length.should eq(1)
    fields[0].name.should eq('The visibility')
    fields[0].code.should eq('visibility')
    fields[0].kind.should eq('select_one')
    fields[0].config.should eq('options' => [{'code' => 'public', 'label' => 'public'}, {'code' => 'private', 'label' => 'private'}])

    sites = collection.sites.all
    sites.length.should eq(3)

    sites[0].properties.should eq({'visibility' => 'public'})
    sites[1].properties.should eq({'visibility' => 'private'})
    sites[2].properties.should eq({'visibility' => 'private'})
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

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    layers = collection.layers.all
    layers.length.should eq(1)
    layers[0].name.should eq(collection.name)

    fields = layers[0].fields.all
    fields.length.should eq(1)
    fields[0].name.should eq('The visibility')
    fields[0].code.should eq('visibility')
    fields[0].kind.should eq('select_one')
    fields[0].config.should eq('options' => [{'code' => '1', 'label' => 'public'}, {'code' => '0', 'label' => 'private'}])

    sites = collection.sites.all
    sites.length.should eq(3)

    sites[0].properties.should eq({'visibility' => '1'})
    sites[1].properties.should eq({'visibility' => '0'})
    sites[2].properties.should eq({'visibility' => '0'})
  end

  it "imports with groups" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Country', 'Province']
      csv << ['Foo1', 'Argentina', 'Buenos Aires']
      csv << ['Foo2', 'Argentina', 'Buenos Aires']
      csv << ['Bar', 'Argentina', 'Cordoba']
      csv << ['Baz', 'Cambodia', 'Phnom Penh']
      csv << ['', '', '']
    end

    specs = [
      {name: 'Name', kind: 'name'},
      {name: 'Province', kind: 'group', level: 2},
      {name: 'Country', kind: 'group', level: 1},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    root_sites = collection.root_sites.all
    root_sites.length.should eq(2)
    root_sites[0].name.should eq('Argentina')
    root_sites[0].should be_group

      argentina_sites = root_sites[0].sites.all
      argentina_sites.length.should eq(2)
      argentina_sites[0].name.should eq('Buenos Aires')
      argentina_sites[0].should be_group

        buenos_aires_sites = argentina_sites[0].sites.all
        buenos_aires_sites.length.should eq(2)
        buenos_aires_sites[0].name.should eq('Foo1')
        buenos_aires_sites[0].should_not be_group
        buenos_aires_sites[1].name.should eq('Foo2')
        buenos_aires_sites[1].should_not be_group

      argentina_sites[1].name.should eq('Cordoba')
      argentina_sites[1].should be_group

        cordoba_sites = argentina_sites[1].sites.all
        cordoba_sites.length.should eq(1)
        cordoba_sites[0].name.should eq('Bar')
        cordoba_sites[0].should_not be_group

    root_sites[1].name.should eq('Cambodia')
    root_sites[1].should be_group

      cambodia_sites = root_sites[1].sites.all
      cambodia_sites.length.should eq(1)
      cambodia_sites[0].name.should eq('Phnom Penh')
      cambodia_sites[0].should be_group

        phnom_penh_sites = cambodia_sites[0].sites.all
        phnom_penh_sites.length.should eq(1)
        phnom_penh_sites[0].name.should eq('Baz')
        phnom_penh_sites[0].should_not be_group
  end

  it "imports with groups computes geometry in memory" do
    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Country', 'Province', 'Lat', 'Lon']
      csv << ['Foo1', 'Argentina', 'Buenos Aires', '10.0', '30.0']
      csv << ['Foo2', 'Argentina', 'Buenos Aires', '20.0', '40.0']
      csv << ['Bar', 'Argentina', 'Cordoba', '0', '50']
      csv << ['Baz', 'Cambodia', 'Phnom Penh', '1', '2']
      csv << ['', '', '']
    end

    specs = [
      {name: 'Name', kind: 'name'},
      {name: 'Province', kind: 'group', level: 2},
      {name: 'Country', kind: 'group', level: 1},
      {name: 'Lat', kind: 'lat'},
      {name: 'Lon', kind: 'lng'},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    collection.reload
    assert_in_location collection, ((1 + 7.5) / 2), ((2 + 42.5) / 2)

    root_sites = collection.root_sites.all
    root_sites.length.should eq(2)
    root_sites[0].name.should eq('Argentina')
    assert_in_bounds root_sites[0], 0, 20, 30, 50
    assert_in_location root_sites[0], 7.5, 42.5

      argentina_sites = root_sites[0].sites.all
      argentina_sites.length.should eq(2)
      argentina_sites[0].name.should eq('Buenos Aires')
      assert_in_bounds argentina_sites[0], 10, 20, 30, 40
      assert_in_location argentina_sites[0], 15, 35

        buenos_aires_sites = argentina_sites[0].sites.all
        buenos_aires_sites.length.should eq(2)
        buenos_aires_sites[0].name.should eq('Foo1')
        assert_in_bounds buenos_aires_sites[0], 10, 10, 30, 30

        buenos_aires_sites[1].name.should eq('Foo2')
        assert_in_bounds buenos_aires_sites[1], 20, 20, 40, 40

      argentina_sites[1].name.should eq('Cordoba')
      assert_in_bounds argentina_sites[1], 0, 0, 50, 50

        cordoba_sites = argentina_sites[1].sites.all
        cordoba_sites.length.should eq(1)
        cordoba_sites[0].name.should eq('Bar')
        assert_in_bounds cordoba_sites[0], 0, 0, 50, 50
  end

  def assert_in_bounds(site, min_lat, max_lat, min_lng, max_lng)
    site.min_lat.to_f.should eq(min_lat.to_f)
    site.max_lat.to_f.should eq(max_lat.to_f)
    site.min_lng.to_f.should eq(min_lng.to_f)
    site.max_lng.to_f.should eq(max_lng.to_f)
  end

  def assert_in_location(site, lat, lng)
    site.lat.to_f.should eq(lat.to_f)
    site.lng.to_f.should eq(lng.to_f)
  end
end
