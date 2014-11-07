
def create_method(name, &block)
  snaked_name_as_sym = name.underscore.gsub(" ","_").to_sym
  self.class.send(:define_method, snaked_name_as_sym, &block)
end

shared_context "collections structure", uses_collections_structure: true do

  def create_collection_with_examples(name, options={})
    coll = collection.make! name: name
    layer = options[:layer] || options[:fields_on] || layer.make!(collection: coll, name: "#{name} layer")
    field = field.make!(collection: coll, layer: layer, name: "#{name} field")

    site = Site.make!(layer: layer,
                          field: field,
                          name: "#{name} site")

    create_method name do
      coll.reload
    end

    unless options[:layer]
      create_method "#{name}_layer" do
        layer.reload
      end
    end

    create_method "#{name}_field" do
      field.reload
    end

    create_method "#{name}_site" do
      site.reload
    end

    return
  end

  before :each do
    create_collection_with_examples "WHO African Region"
    create_collection_with_examples "Rwanda", parent: who_african_region, fields_on: who_african_region_layer
    create_collection_with_examples "Kenya", parent: who_african_region, fields_on: who_african_region_layer
    create_collection_with_examples "Tanzania", parent: who_african_region, fields_on: who_african_region_layer


    create_collection_with_examples "WHO South-East Asia Region"

    create_collection_with_examples "WHO European Region"
    create_collection_with_examples "France", parent: who_european_region, fields_on: who_european_region_layer
    create_collection_with_examples "Spain", parent: who_european_region, fields_on: who_european_region_layer
    create_collection_with_examples "Italy", parent: who_european_region, fields_on: who_european_region_layer
  end

end

