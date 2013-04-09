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
    match 'collections/:collection_id/fred_api/v1/facilities/:id' => 'fred_api#show_facility', :via => :get, as: :show_facility
    match 'collections/:collection_id/fred_api/v1/facilities' => 'fred_api#facilities', :via => :get, as: :facilities
    match 'collections/:collection_id/fred_api/v1/facilities/:id' => 'fred_api#delete_facility', :via => :delete, as: :delete_facility
    match 'collections/:collection_id/fred_api/v1/facilities' => 'fred_api#create_facility', :via => :post, as: :create_facility
    match 'collections/:collection_id/fred_api/v1/facilities/:id' => 'fred_api#update_facility', :via => :put, as: :update_facility
  }
end
