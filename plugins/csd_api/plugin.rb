class CsdApi::Plugin < Plugin

  routes {
    match 'collections/:collection_id/csd_api/get_directory_modifications' => 'csd_api#get_directory_modifications', :via => :post, as: :get_directory_modifications
  }
end
