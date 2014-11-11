
def create_method(name, &block)
  snaked_name_as_sym = name.underscore.gsub(" ","_").to_sym
  self.class.send(:define_method, snaked_name_as_sym, &block)
end

shared_context "collections structure", uses_collections_structure: true do

  def create_collection_with_examples(name, options={})
    coll = Collection.make name: name
    layer = options[:layer] || options[:fields_on] || Layer.make(collection: coll, name: "#{name} layer")
    field = Field::NumericField.make(collection: coll, layer: layer, name: "#{name} field")

    create_method name do
      coll.reload
    end

    create_method "#{name}_layer" do
      layer.reload
    end

    create_method "#{name}_field" do
      field.reload
    end

  end

  def create_site_for_collection(collection_name, site_name)
    coll = Collection.find_by_name(collection_name)
    site = Site.make(collection: coll, name: "#{site_name} site")

    create_method "#{site_name}_site" do
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
  end

end

