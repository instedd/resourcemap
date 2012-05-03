ResourceMap::Application.routes.draw do
  devise_for :users

  resources :collections do
    resources :sites
    resources :layers do
      member do
        put :set_order
      end
    end
    resources :fields
    resources :memberships do
      collection do
        get 'invitable'
      end
      member do
        post 'set_layer_access'
      end
    end
    get 'members'
    get 'thresholds'
    get 'reminders'
    get 'settings'
    get 'download_as_csv'
    get 'csv_template'
    get 'max_value_of_property'

    post 'upload_csv'

    get 'import_wizard'
    post 'import_wizard_upload_csv'
    get 'import_wizard_adjustments'
    post 'import_wizard_execute'

    get 'recreate_index'

    member do
      get 'search'
    end
  end

  resources :sites do
    get 'root_sites'
    get 'search', :on => :collection

    post 'update_property'
  end

  resources :activities, :only => [:index], :path => 'activity'
  resources :gateways

  get 'terms_and_conditions', :to => redirect('/')

  namespace :api do
    get 'collections/:id' => 'collections#show',as: :collection
    get 'collections/:id/count' => 'collections#count',as: :count
    get 'sites/:id' => 'sites#show', as: :site
    get 'activity' => 'activities#index', as: :activity
  end

  root :to => 'home#index'
end
