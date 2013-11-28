class CsdApi::Plugin < Plugin
  Collection
  extend_model \
    class: Collection,
    with: Collection::CSDApiConcern

  routes {
    match 'collections/:collection_id/csd_api/get_directory_modifications' => 'csd_api#get_directory_modifications', :via => :post, as: :get_directory_modifications
  }
end
