class CsdApi::Plugin < Plugin
  #collection_tab '/csd_api_config_tab'

  Collection
  extend_model \
    class: Collection,
    with: Collection::CSDApiConcern

  extend_model \
    class: Field,
    with: Field::CSDApiConcern

  #Why's this here?
  extend_model \
    class: Site,
    with: Site::AlertConcerns

  routes {
    post 'collections/:collection_id/csd_api/get_directory_modifications' => 'csd_api#get_directory_modifications', as: :get_directory_modifications
    post 'collections/:collection_id/csd_api/get_service_modifications' => 'csd_api#get_service_modifications', as: :get_service_modifications
    # match 'collections/:collection_id/csd_api/get_organization_modifications' => 'csd_api#get_organization_modifications', :via => :post, as: :get_service_modifications
    get 'collections/:collection_id/csd_api' => 'csd_api#index', :as => :csd_api_settings
  }
end
