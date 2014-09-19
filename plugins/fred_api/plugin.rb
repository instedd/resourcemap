class FredApi::Plugin < Plugin
  Field::IdentifierField
  field_type \
    name: 'identifier',
    css_class: 'lgovernment',
    small_css_class: 'sgovernment',
    edit_view: 'fields/identifier_edit_view',
    property_editor: 'fields/identifier_editor',
    sample_value: 'XYZ123'

  extend_model \
    class: Field,
    with: Field::FredApiConcern

  extend_model \
    class: Search,
    with: Search::FredApiConcern

  extend_model \
    class: Site,
    with: Site::UuidConcern


  routes {
    get 'collections/:collection_id/fred_api/v1/facilities/:id' => 'fred_api#show_facility', as: :show_facility
    get 'collections/:collection_id/fred_api/v1/facilities' => 'fred_api#facilities', as: :facilities
    delete 'collections/:collection_id/fred_api/v1/facilities/:id' => 'fred_api#delete_facility', as: :delete_facility
    post 'collections/:collection_id/fred_api/v1/facilities' => 'fred_api#create_facility', as: :create_facility
    put 'collections/:collection_id/fred_api/v1/facilities/:id' => 'fred_api#update_facility', as: :update_facility
  }
end
