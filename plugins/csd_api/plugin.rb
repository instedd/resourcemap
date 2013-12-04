class CsdApi::Plugin < Plugin
  collection_tab '/csd_api_config_tab'

  Collection
  extend_model \
    class: Collection,
    with: Collection::CSDApiConcern

  routes {
    match 'collections/:collection_id/csd_api/get_directory_modifications' => 'csd_api#get_directory_modifications', :via => :post, as: :get_directory_modifications
    match 'collections/:collection_id/csd_api' => 'csd_api#index', :via => :get, :as => :csd_api_settings

  }
end
