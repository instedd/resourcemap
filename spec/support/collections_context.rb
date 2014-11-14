def create_method(name, &block)
  snaked_name_as_sym = name.underscore.gsub(" ","_").to_sym
  self.class.send(:define_method, snaked_name_as_sym, &block)
end

shared_context "collections structure", uses_collections_structure: true do

  def create_collection_with_examples(name, options={})

    coll = Collection.make name: name
    layer = options[:layer] || options[:fields_on] || Layer.make(collection: coll, name: "#{name} layer")
    field = Field::NumericField.make(collection: coll, layer: layer, name: "#{name} field")
    create_shortcut_methods(name,coll,layer,field)
  end

  def create_shortcut_methods(name, collection, layer, field)
    create_method name do
      collection.reload
    end

    create_method "#{name}_layer" do
      layer.reload
    end

    if field
      create_method "#{name}_field" do
        field.reload
      end
    end
  end

  def create_site_for_collection(collection_name, site_name)
    coll = Collection.find_by_name(collection_name)
    site = Site.make(collection: coll, name: "#{site_name} site")

    create_method "#{site_name}_site" do
      site.reload
    end
  end

  def create_collection_with_all_fields(name, options={})
    coll = Collection.make name: name
    coll.sites.make name: "Second Site"
    layer = options[:layer] || options[:fields_on] || Layer.make(collection: coll, name: "#{name} layer")
    all_fields = []

    numeric_field = layer.numeric_fields.make(name: "#{name}_numeric_field", code: "numeric")
    all_fields.push(numeric_field)

    text_field = layer.text_fields.make(name: "#{name}_text_field", code: "text")
    all_fields.push(text_field)

    select_one_field = layer.select_one_fields.make(config: {options: [{id: '1', code: 'foo_one', label: 'foo_one'},{id: '2', code: 'bar_one', label: 'bar_one'}]}.with_indifferent_access, name: "#{name}_select_one_field", code: "selone")
    all_fields.push(select_one_field)

    date_field = layer.date_fields.make(name: "#{name}_date_field", code: "date")
    all_fields.push(date_field)

    email_field = layer.email_fields.make(name: "#{name}_email_field", code: "email")
    all_fields.push(email_field)

    identifier_field = layer.identifier_fields.make(name: "#{name}_identifier_field", code: 'identifier', :config => {"context" => "MOH", "agency" => "Manas", "format" => "Normal"})
    all_fields.push(identifier_field)

    phone_field = layer.phone_fields.make(name: "#{name}_phone_field", code: 'phone')
    all_fields.push(phone_field)

    site_field = layer.site_fields.make(name: "#{name}_site_field", code: 'site')
    all_fields.push(site_field)

    user_field = layer.user_fields.make(name: "#{name}_user_field", code: 'user')
    all_fields.push(user_field)

    yes_no_field = layer.yes_no_fields.make(name: "#{name}_yes_no_field", code: 'yes_no')
    all_fields.push(yes_no_field)

    all_fields.each do |f|
      create_method f.name do
        f.reload
      end
    end

    create_shortcut_methods(name,coll,layer,nil)

  end

  def create_site_with_all_fields(collection_name, site_name)
    c = Collection.find_by_name(collection_name)
    s = Site.find_by_name("Second site")

    create_method "#{collection_name}_auxiliar_site" do
      s.reload
    end

    user2 = User.make(:email => 'user2@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    c.memberships.create! user_id: user2.id
    kind_and_value = {
      "numeric" => 987654321,
      "text" => "before_changed",
      "select_one" => 1,
      "select_many" => [1],
      "hierarchy" => '0',
      "date" => '2013-12-15T00:00:00Z',
      "email" => 'before@manas.com.ar',
      "identifier" => '42',
      "phone" => '4444',
      "site" => s.id,
      "user" => user2.email,
      "yes_no" => true
    }
    fields = c.fields
    properties = {}

    fields.each do |f|
      properties[f.es_code] = kind_and_value[f.kind]
    end

    site = c.sites.make properties: properties, name: site_name

    create_method "#{collection_name}_#{site_name}" do
      site.reload
    end
  end

  before :each do
    create_collection_with_examples "WHO African Region"
    create_site_for_collection("WHO African Region", "Rwanda")
    create_site_for_collection("WHO African Region", "Kenya")
    create_site_for_collection("WHO African Region", "Tanzania")

    create_collection_with_examples "WHO European Region"
    create_site_for_collection("WHO European Region", "France")
    create_site_for_collection("WHO European Region", "Spain")
    create_site_for_collection("WHO European Region", "Italy")

    create_collection_with_all_fields("Multicollection")
    create_site_with_all_fields("Multicollection","Multisite")
  end

end

