class Alerts::Plugin < Plugin

  collection_tab '/alerts_tab'

  extend_model \
    class: Site,
    with: Site::TemplateConcerns

  extend_model \
    class: Site,
    with: Site::AlertConcerns

  field_type \
    name: 'user',
    css_class: 'luser',
    edit_view: 'fields/user_edit_view'

  field_type \
    name: 'email',
    css_class: 'lmessage',
    edit_view: 'fields/email_edit_view'

  field_type \
    name: 'phone',
    css_class: 'lphone',
    edit_view: 'fields/phone_edit_view'

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
