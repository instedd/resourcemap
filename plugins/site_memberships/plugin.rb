class SiteMemberships::Plugin < Plugin

  collection_tab '/site_memberships_tab'

  # field_type \
  #   name: 'user',
  #   css_class: 'luser',
  #   edit_view: 'fields/user_edit_view'

  routes {
    resources :collections do
      resources :site_memberships
    end
  }
end
