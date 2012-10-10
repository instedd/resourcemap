class Alerts::Plugin < Plugin

  collection_tab '/alerts_tab'
  map_header '/alerts_map_header'

  extend_model \
    class: Site,
    with: Site::TemplateConcerns

  extend_model \
    class: Site,
    with: Site::AlertConcerns

  field_type \
    name: 'email',
    css_class: 'lmessage',
    small_css_class: 'smessage',
    edit_view: 'fields/email_edit_view'

  field_type \
    name: 'phone',
    css_class: 'lphone',
    small_css_class: 'sphone',
    edit_view: 'fields/phone_edit_view'

  clusterer \
    map: ->(site, tmp) do
      tmp[:alert_count] ||= 0
      tmp[:alert_count] += (site[:alert] == 'true' ? 1 : 0)
    end,
    reduce: ->(tmp, cluster) { cluster[:alert_count] = tmp[:alert_count] }

  routes {
    resources :collections do
      resources :thresholds do
        member do
          post :set_order
        end
      end
    end
  }
end
