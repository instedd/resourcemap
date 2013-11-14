class CsdApi::Plugin < Plugin

  routes {
    match 'collections/:collection_id/csd_api/directories' => 'csd_api#directories', :via => :post, as: :directories
  }
end
