class Alerts::Plugin < Plugin

  collection_tab '/alerts_tab'

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