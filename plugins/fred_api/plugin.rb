class FredApi::Plugin < Plugin
  extend_model \
    class: Field,
    with: Field::FredApiConcern

  extend_model \
    class: Search,
    with: Search::FredApiConcern

  routes {
    match 'collections/:collection_id/fred_api/v1/facilities/:id' => 'fred_api#show_facility', :via => :get, as: :show_facility
    match 'collections/:collection_id/fred_api/v1/facilities' => 'fred_api#facilities', :via => :get, as: :facilities
    match 'collections/:collection_id/fred_api/v1/facilities/:id' => 'fred_api#delete_facility', :via => :delete, as: :delete_facility
  }
end
