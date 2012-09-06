class SiteMemberships::Plugin < Plugin

  collection_tab '/site_memberships_tab'

  routes {
    resources :collections do
      resources :site_memberships
    end
  }
end
