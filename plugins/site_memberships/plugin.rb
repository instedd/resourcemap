class SiteMemberships::Plugin < Plugin

  collection_tab '/site_memberships_tab'

  extend_model \
    class: Collection,
    with: Collection::SiteMembershipsConcern

  routes {
    resources :collections do
      resources :site_memberships do
        post 'set_access', on: :collection
      end
    end
  }
end
