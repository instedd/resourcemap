class SiteMemberships::Plugin < Plugin

  collection_tab '/site_memberships_tab'

  extend_model \
    class: Collection,
    with: Collection::SiteMembershipConcerns

  routes {
    resources :collections do
      resources :site_memberships
    end
  }
end
