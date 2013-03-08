class Alerts::Plugin < Plugin

  collection_tab '/alerts_tab'
  map_header '/alerts_map_header'

  extend_model \
    class: Site,
    with: Site::TemplateConcerns

  extend_model \
    class: Site,
    with: Site::AlertConcerns

  Field::EmailField
  field_type \
    name: 'email',
    css_class: 'lmessage',
    small_css_class: 'smessage',
    edit_view: 'fields/email_edit_view',
    sample_value: 'an@email.com'

  Field::PhoneField
  field_type \
    name: 'phone',
    css_class: 'lphone',
    small_css_class: 'sphone',
    edit_view: 'fields/phone_edit_view',
    sample_value: '85512345678'

  clusterer \
    map: ->(site, tmp) do
      tmp[:alert_count] ||= 0
      tmp[:alert_count] += (site[:alert] == 'true' ? 1 : 0)
      tmp[:alert] = true if site[:alert] == 'true'
      tmp[:ord] =  if site[:ord] then if site[:ord].to_i < tmp[:ord].to_i then site[:ord]  else tmp[:ord]  end else '100' end
    end,

    reduce: ->(tmp, cluster) do 
      cluster[:alert_count] = tmp[:alert_count] 
      cluster[:color] = tmp[:status] && tmp[:alert] ? Collection.find(tmp[:collection_id]).thresholds.find_by_ord(tmp[:ord]).try(:color) : ''
      cluster[:alert] = tmp[:alert]
    end

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
