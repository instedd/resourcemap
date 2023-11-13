require 'spec_helper'

describe Activity, :type => :model do
  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }

  it "creates one when collection is created" do
    assert_activity 'collection', 'created',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'data' => {'name' => collection.name},
      'description' => "Collection '#{collection.name}' was created"
  end

  it "creates one when layer is created" do
    Activity.delete_all

    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

    assert_activity 'layer', 'created',
      'collection_id' => collection.id,
      'layer_id' => layer.id,
      'user_id' => user.id,
      'data' => {'name' => layer.name, 'fields' => [{'id' => layer.fields.first.id, 'kind' => 'text', 'code' => 'foo', 'name' => 'Foo'}]},
      'description' => "Layer '#{layer.name}' was created with fields: Foo (foo)"
  end

  context "layer changed" do
    it "creates one when layer's name changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

      Activity.delete_all

      layer.name = 'Layer2'
      layer.save!

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'name' => ['Layer1', 'Layer2']}},
        'description' => "Layer 'Layer1' was renamed to '#{layer.name}'"
    end

    it "creates one when layer's field is added" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}]

      Activity.delete_all

      layer.update_attributes! fields_attributes: [{kind: 'text', code: 'two', name: 'Two', ord: 2}]

      field = layer.fields.last

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'added' => [{'id' => field.id, 'code' => field.code, 'name' => field.name, 'kind' => field.kind}]}},
        'description' => "Layer 'Layer1' changed: text field 'Two' (two) was added"
    end

    it "creates one when layer's field's code changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, code: 'one1', name: 'One', ord: 1}]

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'changed' => [{'id' => field.id, 'code' => ['one', 'one1'], 'name' => 'One', 'kind' => 'text'}]}},
        'description' => "Layer 'Layer1' changed: text field 'One' (one) code changed to 'one1'"
    end

    it "creates one when layer's field's name changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, code: 'one', name: 'One1', ord: 1}]

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'changed' => [{'id' => field.id, 'code' => 'one', 'name' => ['One', 'One1'], 'kind' => 'text'}]}},
        'description' => "Layer 'Layer1' changed: text field 'One' (one) name changed to 'One1'"
    end

    it "creates one when layer's field's options changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'select_one', code: 'one', name: 'One', config: {'options' => [{'code' => '1', 'label' => 'One'}]}, ord: 1}]

      Activity.delete_all

      field = layer.fields.last

      begin
        layer.update_attributes! fields_attributes: [{id: field.id, code: 'one', name: 'One', kind: 'select_one', config: {'options' => [{'code' => '2', 'label' => 'Two'}]}, ord: 1}]
      rescue Exception => ex
        puts ex.backtrace
      end

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'changed' => [{'id' => field.id, 'code' => 'one', 'name' => 'One', 'kind' => 'select_one', 'config' => [{'options' => [{'code' => '1', 'label' => 'One'}]}, {'options' => [{'code' => '2', 'label' => 'Two'}]}]}]}},
        'description' => %(Layer 'Layer1' changed: select_one field 'One' (one) options changed from ["One (1)"] to ["Two (2)"])
    end

    it "creates one when layer's field is removed" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}, {kind: 'text', code: 'two', name: 'Two', ord: 2}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, _destroy: true}]

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'deleted' => [{'id' => field.id, 'code' => 'two', 'name' => 'Two', 'kind' => 'text'}]}},
        'description' => "Layer 'Layer1' changed: text field 'Two' (two) was deleted"
    end
  end

  it "creates one when layer is destroyed" do
    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

    Activity.delete_all

    layer.destroy

    assert_activity 'layer', 'deleted',
      'collection_id' => collection.id,
      'layer_id' => layer.id,
      'user_id' => user.id,
      'data' => {'name' => layer.name},
      'description' => "Layer '#{layer.name}' was deleted"
  end

  it "creates one after creating a site" do
    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'beds', name: 'Beds', ord: 1}]
    field = layer.fields.first

    Activity.delete_all

    site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {field.es_code => 20}, user: user

    assert_activity 'site', 'created',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'site_id' => site.id,
      'data' => {'name' => site.name, 'lat' => site.lat, 'lng' => site.lng, 'properties' => site.properties},
      'description' => "Site '#{site.name}' was created"
  end

  it "creates one after importing a csv through wizard" do
    Activity.delete_all

    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Lat', 'Lon']
      csv << ['Site', '30', '40']
    end

    specs = [
      {header: 'Name', use_as: 'name'},
      {header: 'Lat', use_as: 'lat'},
      {header: 'Lon', use_as: 'lng'}
    ]

    ImportWizard.import user, collection, 'foo.csv', csv_string
    ImportWizard.mark_job_as_pending user, collection
    ImportWizard.execute user, collection, specs

    activities = Activity.all
    expect(activities.length).to eq(2)
    expect(activities[1].item_type).to eq('site')
    expect(activities[1].action).to eq('created')
    expect(activities[0].item_type).to eq('collection')
    expect(activities[0].action).to eq('imported')
  end

  context "site changed" do
    let!(:layer) { collection.layers.make user: user, fields_attributes: [{kind: 'numeric', code: 'beds', name: 'Beds', ord: 1}, {kind: 'numeric', code: 'tables', name: 'Tables', ord: 2}, {kind: 'text', code: 'text', name: 'Text', ord: 3}] }
    let(:beds) { layer.fields.first }
    let(:tables) { layer.fields.second }
    let(:text) { layer.fields.third }

    it "creates one after changing one site's name" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.name = 'Bar'
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => 'Foo', 'changes' => {'name' => ['Foo', 'Bar']}},
        'description' => "Site 'Foo' was renamed to 'Bar'"
    end

    it "creates one after changing one site's location" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = 15.1234567
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'lat' => [10.0, 15.123457], 'lng' => [20.0, 20.0]}},
        'description' => "Site '#{site.name}' changed: location changed from (10.0, 20.0) to (15.123457, 20.0)"
    end

    it "creates one after adding location in site without location" do
      site = collection.sites.create! name: 'Foo', properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = 15.1234567
      site.lng = 34.123456

      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'lat' => [ nil, 15.123457], 'lng' => [nil, 34.123456]}},
        'description' => "Site '#{site.name}' changed: location changed from (nothing) to (15.123457, 34.123456)"
    end

    it "creates one after removing location in site with location" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = nil
      site.lng = nil

      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'lat' => [10.0, nil], 'lng' => [20.0, nil]}},
        'description' => "Site '#{site.name}' changed: location changed from (10.0, 20.0) to (nothing)"
    end

    it "creates one after adding one site's property" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties[beds.es_code] = 30
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'properties' => [{}, {beds.es_code => 30}]}},
        'description' => "Site '#{site.name}' changed: 'beds' changed from (nothing) to 30"
    end

    it "creates one after deleting one site's property" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 30}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties[beds.es_code] = nil
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'properties' => [{beds.es_code => 30}, {}]}},
        'description' => "Site '#{site.name}' changed: 'beds' changed from 30 to (nothing)"
    end

    it "creates one after changing one site's property" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties[beds.es_code] = 30
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'properties' => [{beds.es_code => 20}, {beds.es_code => 30}]}},
        'description' => "Site '#{site.name}' changed: 'beds' changed from 20 to 30"
    end

    it "creates one after changing many site's properties" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20, text.es_code => 'foo'}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties[beds.es_code] = 30
      site.properties[text.es_code] = 'bar'
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'properties' => [{beds.es_code => 20, text.es_code => 'foo'}, {beds.es_code => 30, text.es_code => 'bar'}]}},
        'description' => "Site '#{site.name}' changed: 'beds' changed from 20 to 30, 'text' changed from 'foo' to 'bar'"
    end

    it "doesn't create one after siglaning properties will change but they didn't change" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.save!

      expect(Activity.count).to eq(0)
    end

    it "doesn't create one if lat/lng updated but not changed" do
      site = collection.sites.create! name: 'Foo', lat: "-1.9537", lng: 0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = "-1.9537"
      site.lng = 0
      site.save!

      expect(Activity.count).to eq(0)
    end

    it "creates one after changing lat to nil" do
      site = collection.sites.create! name: 'Foo', lat: 0, lng: "30.10309", properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = nil
      site.save!

      expect(Activity.count).to eq(1)
      activities = Activity.all
      assert_activity 'site', 'changed',
        'data' => {"name" => site.name, "changes" => {"lat" => [0, nil], "lng" => [30.10309, 30.10309]}}

    end

    it "creates one after changing lng to nil" do
      site = collection.sites.create! name: 'Foo', lat: "-1.9537", lng: "30.10309", properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lng = nil
      site.save!

      expect(Activity.count).to eq(1)
      activities = Activity.all
      assert_activity 'site', 'changed',
        'data' => {"name" => site.name, "changes" => {"lat" => [-1.9537, -1.9537], "lng" => [30.10309, nil]}}

    end

    it "creates one after changing lat and lng from nil to a value" do
      site = collection.sites.create! name: 'Foo', properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = "44.123"
      site.lng = "-33.2"
      site.save!

      expect(Activity.count).to eq(1)
      activities = Activity.all
      assert_activity 'site', 'changed',
        'data' => {"name" => site.name, "changes" => {"lat" => [nil, 44.123], "lng" => [nil, -33.2]}}

    end

    it "creates one after changing lat and lng to nil" do
      site = collection.sites.create! name: 'Foo', lat: "-1.9537", lng: "30.10309", properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = nil
      site.lng = nil
      site.save!

      expect(Activity.count).to eq(1)
      activities = Activity.all
      assert_activity 'site', 'changed',
        'data' => {"name" => site.name, "changes" => {"lat" => [-1.9537, nil], "lng" => [30.10309, nil]}}

    end

    it "creates one after changing lat more than 1e-04" do
      site = collection.sites.create! name: 'Foo', lat: "-1.9537", lng: "30.10309", properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = site.lat + 1e-04
      site.save!

      expect(Activity.count).to eq(1)
      activities = Activity.all
      assert_activity 'site', 'changed',
        'data' => {"name" => site.name, "changes" => {"lat" => [-1.9537, site.lat], "lng" => [30.10309, 30.10309]}}

    end

    it "creates one after changing lng more than 1e-04" do
      site = collection.sites.create! name: 'Foo', lat: "-1.9537", lng: "30.10309", properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lng = site.lng + 1e-04
      site.save!

      expect(Activity.count).to eq(1)
      activities = Activity.all
      assert_activity 'site', 'changed',
        'data' => {"name" => site.name, "changes" => {"lat" => [-1.9537, -1.9537], "lng" => [30.10309, site.lng]}}

    end

    it "doesn't create one after changing lat less than 1e-04" do
      site = collection.sites.create! name: 'Foo', lat: "-1.9537", lng: "30.10309", properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = site.lat + 1e-05
      site.save!

      expect(Activity.count).to eq(0)
    end

    it "doesn't create one after changing lng less than 1e-04" do
      site = collection.sites.create! name: 'Foo', lat: "-1.9537", lng: "30.10309", properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lng = site.lng + 1e-05
      site.save!

      expect(Activity.count).to eq(0)
    end
  end

  it "creates one after destroying a site" do
    site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, location_mode: :manual, user: user

    Activity.delete_all

    site.destroy

    assert_activity 'site', 'deleted',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'site_id' => site.id,
      'data' => {'name' => site.name},
      'description' => "Site '#{site.name}' was deleted"
  end

  def assert_activity(item_type, action, options = {})
    activities = Activity.all
    expect(activities.length).to eq(1)
    expect(activities[0].item_type).to eq(item_type)
    expect(activities[0].action).to eq(action)
    options.each do |key, value|
      expect(activities[0].send(key)).to eq(value)
    end
  end
end
